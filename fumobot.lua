local weapon_categories = {"general", "rifles", "smgs", "pistols", "heavy pistols", "scout", "awp" };

local master            = menu.add_checkbox("kitkat legit", "enable legitbot");
local weapons           = menu.add_selection("kitkat legit", "weapon", weapon_categories);
local use_only_global   = menu.add_checkbox("kitkat legit", "use only global config");

local aim_text          = menu.add_text("kitkat keybindings", "aimbot key")
local aim_key           = aim_text:add_keybind("aimbot key")
local trigger_text      = menu.add_text("kitkat keybindings", "triggerbot key")
local trigger_key       = trigger_text:add_keybind("triggerbot key")

local show_fov          = menu.add_checkbox("kitkat visuals", "show fov");

local global_category = "General";
local last_weapon_name = "";
local scaled_fov = 0
local fov = 0;

local options = (function()
    local space = function(amount) 
        local str = "";

        for i = 0, amount do
            str = str .. " ";
        end

        return str;
    end

    local arr = { };

    for i = 1, #weapon_categories do
        local current = weapon_categories[i];
        local id      = space(i);

        arr[current] = { 
            hitbox         = menu.add_selection("kitkat legit", string.format("Hitbox%s", id), {"Head", "Upper chest", "Chest", "Stomach", "Pelvis"});
            aim_fov          = menu.add_slider("kitkat legit", string.format("aim fov%s", id), 1, 60);
            dyn_fov          = menu.add_checkbox("kitkat legit", string.format("dynamic fov%s", id));
            min_dyn_fov      = menu.add_slider("kitkat legit", string.format("min fov%s", id), 1, 60);
            max_dyn_fov      = menu.add_slider("kitkat legit", string.format("max fov%s", id), 1, 60);
            comp_recoil      = menu.add_checkbox("kitkat legit", string.format("compensate recoil%s", id));
            comp_recoil_x    = menu.add_slider("kitkat legit", string.format("compensate recoil x%s", id), 0, 100);
            comp_recoil_y    = menu.add_slider("kitkat legit", string.format("compensate recoil y%s", id), 0, 100);
            comp_after       = menu.add_slider("kitkat legit", string.format("compensate after x shots%s", id), 0, 30);

            trigger_enable   = menu.add_checkbox("kitkat trigger", string.format("trigger%s", id));
        }
    end

    return arr;
end)()

includes = function(tbl, element)
    for v, k in pairs(tbl) do
        if k == element then
            return true
        end
    end

    return false
end

clamp = function(val, min, max)
    if val < min then
        val = min
    end
    if val > max then
        val = max
    end
    return val
end

lerp = function(min, max, factor)
    factor = clamp(factor, 0.0, 1.0)
    local lerp_result = (1-factor)*max+factor*min

    return clamp(lerp_result, min, max)
end

vector_add = function(vec1, vec2)
    return Vector(vec1.x + vec2.x, vec1.y + vec2.y, vec1.z + vec2.z);
end

normalize_vector = function(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);

    return vec3_t(vec.x / length, vec.y / length, vec.z / length);
end

vecdot = function(vec1, vec2)
    return vec1.x * vec2.x + vec1.y * vec2.y
end

angle2vector = function(pitch, yaw)
    local x = math.cos(math.rad(pitch)) * math.cos(math.rad(yaw));
    local y = math.cos(math.rad(pitch)) * math.sin(math.rad(yaw));

    return vec2_t(x, y);
end

function distance(x, y)
	return math.sqrt( (y.x - x.x)^2 + (y.y-x.y)^2)
end

local function r2d(radians) 
    return radians * 180 / math.pi
end

local function pos2angle(vec1, vec2) 
    local x = vec2.x - vec1.x
    local z = vec2.y - vec1.y
    local y = vec1.z - vec2.z
     
     return angle_t(-r2d(math.atan2(y, math.sqrt(x * x + z * z))) ,r2d(math.atan2(z, x))+180 ,0)
 end

local function calc_fov(vec0, vec1, vec2)
    local norm_vec = normalize_vector(vec3_t(vec1.x - vec0.x, vec1.y - vec0.y, vec1.z - vec0.z));
    local dot_prod = vecdot(norm_vec, vec2);
    local cos_inverse = math.acos(dot_prod);
   
    return(180 / math.pi)*cos_inverse;
end

local function closest_player(vec, vec_angles) 
    local players = entity_list.get_players(true);

    local nearest_player = nil
    local nearest_fov = math.huge;

    for idx, plyr in pairs(players) do
        if not plyr:is_alive() then goto skip end

        local fov_to_player = calc_fov(plyr:get_eye_position(), vec, vec_angles);
        if fov_to_player <= nearest_fov then 
            nearest_player = plyr;
            nearest_fov = fov_to_player;
        end
        ::skip::
    end

    return nearest_player, nearest_fov;
end

local legitbot = {
    fov = 0,
    last_trigger_time = nil,
}

function legitbot:do_fov(cmd, local_player) 
    if not master:get() then return end
    if not local_player:is_alive() then return end
    
    local view_angles = engine.get_view_angles();
   
    local vec_angles = angle2vector(view_angles.x, view_angles.y);
    local vec_eye     = local_player:get_eye_position();

    local nearest_player, fov = closest_player(vec_eye, vec_angles);
    local max_dist   =  1000*3
    local min_fov    = min_dyn_fov:get()
    local max_fov    = max_dyn_fov:get()
    local dyn_enabled = dyn_fov:get()

    if nearest_player and nearest_player:is_alive() then 
        local origin = nearest_player:get_prop("m_vecOrigin");
        local lporigin = local_player:get_prop("m_vecOrigin");
        local distance = distance(lporigin, origin);

        scaled_fov = clamp(math.floor(lerp(min_fov, max_fov + 3, (distance/max_dist)*3*1.10)), min_fov, max_fov);
    else
        scaled_fov = min_fov;
    end

    --ternary in lua
    self.fov = dyn_enabled and scaled_fov or aim_fov:get();
end

function legitbot:trigger(local_player, cmd)
    if not client.can_fire() then
        return
    end

    local weapon = local_player:get_active_weapon()
    if weapon == nil then
        return
    end

    local weapon_data = weapon:get_weapon_data()
    if weapon_data == nil then
        return
    end

    start_pos = local_player:get_eye_position();
    local end_pos = start_pos + cmd.viewangles:to_vector():scaled(weapon_data.range)

    local bullet_data = trace.bullet(start_pos, end_pos)
    if not bullet_data.valid then
        return
    end

    if bullet_data.pen_count > 0 then return end 

    if bullet_data.hit_player:is_enemy() then 
       cmd:add_button(e_cmd_buttons.ATTACK)
    end
end

function legitbot:aim_at(local_player, cmd)
    -- the actual aimbot part
    if not master:get() then return end
    if not local_player:is_alive() then return end

    local view_angles = engine.get_view_angles();
   
    local vec_angles = angle2vector(view_angles.x, view_angles.y);
    local vec_eye     = local_player:get_eye_position();

    local nearest_player, fov = closest_player(vec_eye, vec_angles);

    local aim_at = 0
  
    if hitbox:get() == 1 then 
        aim_at = 0
    elseif hitbox:get() == 2 then
        aim_at = 6
    elseif hitbox:get() == 3 then
        aim_at = 5
    elseif hitbox:get() == 4 then
        aim_at = 3
    elseif hitbox:get() == 5 then
        aim_at = 2
    end


    if nearest_player and nearest_player:is_alive() then 
        local hitbox_pos = nearest_player:get_hitbox_pos(aim_at);
        local aim_angle  = pos2angle(hitbox_pos, vec_eye);

        if aim_key:get() then 
            cmd.viewangles = aim_angle;
        end
    end
end

function legitbot:comp_recoil(local_player, cmd) 
    local x = comp_recoil_x:get();
    local y = comp_recoil_y:get();
    local after = comp_after:get();

    local view_angles = engine.get_view_angles();
    local punch_angle = local_player:get_prop("m_aimPunchAngle");
    local fired_shots = local_player:get_prop("m_iShotsFired");

    if fired_shots > after then 
        cmd.viewangles.x = view_angles.x - (punch_angle.x * (x/100));
        cmd.viewangles.y = view_angles.y - (punch_angle.y * (y/100));
    end
end

function legitbot:run(cmd)
    local lp = entity_list.get_local_player();

    if lp == nil then
        return;
    end

    if not lp:is_alive() then 
        return;
    end

    if master:get() then
        self:do_fov(cmd, lp);
        self:aim_at(lp, cmd);
    end

    if comp_recoil:get() then
        self:comp_recoil(lp, cmd);
    end

    if trigger_enable:get() and trigger_key:get() then
        self:trigger(lp, cmd);
    end
end

local function on_setup_command(cmd)
    updateweaponsettings();
    legitbot:run(cmd);
end

function on_paint(text)
    menu_stuff();
  
    local lp = entity_list.get_local_player();

    if lp == nil then
        return;
    end

    if not lp:is_alive() then 
        return;
    end

    local weapon_handle = entity_list.get_local_player():get_prop("m_hActiveWeapon");
    if weapon_handle == nil then
        return nil;
    end

    local weapon = entity_list.get_entity(weapon_handle);
    local weapon_name = weapon:get_name();

    if master:get() and show_fov:get() then 
        local fov = legitbot.fov;
        local fov_to_show = legitbot.fov*6.25
        screen_size = render.get_screen_size(); 

        render.circle(vec2_t(screen_size.x/2, screen_size.y/2), math.floor(fov_to_show+0.5),  color_t(255, 255, 255, 255));
    end

    return text;
end

function updateweaponsettings()
    local weapons = {
        ["pistols"] = { "glock", "usp-s", "p200", "elite", "fiveseven", "cz75a", "tec9", "p25-" },
        ["heavy pistols"] = { "deagle", "revolver" },
        ["scout"] = { "ssg08" },
        ["awp"] = { "awp" },
        ["rifles"] = { "aug", "sg556", "m4a1-s", "m4a1", "ak47", "famas", "galilar"},
        ["smgs"] = { "mac10", "mp9", "mp7", "ump45", "p90", "bizon", "ump45" },
    }

    local lp = entity_list.get_local_player();

    if lp == nil then
        return;
    end

    if not lp:is_alive() then 
        return;
    end

    local weapon_handle = entity_list.get_local_player():get_prop("m_hActiveWeapon");
    if weapon_handle == nil then
        return nil;
    end

    local weapon = entity_list.get_entity(weapon_handle);
    local weapon_name = weapon:get_name();

    if not use_only_global:get() then 
        for category, tbl in pairs(weapons) do 
            if includes(tbl, weapon_name) then 
                global_category = category;

                hitbox  = options[global_category].hitbox;
                aim_fov   = options[global_category].aim_fov;
                dyn_fov   = options[global_category].dyn_fov;
                min_dyn_fov = options[global_category].min_dyn_fov;
                max_dyn_fov = options[global_category].max_dyn_fov;

                trigger_enable = options[global_category].trigger_enable;

                comp_recoil = options[global_category].comp_recoil;
                comp_recoil_x = options[global_category].comp_recoil_x;
                comp_recoil_y = options[global_category].comp_recoil_y;
                comp_after = options[global_category].comp_after;
                return;
            end
        end
    end

    global_category = "general";

    hitbox = options[global_category].hitbox
    aim_fov = options[global_category].aim_fov
    dyn_fov = options[global_category].dyn_fov
    min_dyn_fov = options[global_category].min_dyn_fov
    max_dyn_fov = options[global_category].max_dyn_fov
    comp_recoil = options[global_category].comp_recoil
    comp_recoil_x = options[global_category].comp_recoil_x
    comp_recoil_y = options[global_category].comp_recoil_y

    trigger_enable = options[global_category].trigger_enable
end

menu_stuff = function( ) 
    local enabled_rage   = master:get();
    local global_only    = use_only_global:get();

    local current_category = weapons:get();

    if global_only then 
        weapons:set(1);
    end 

    for i = 1, #weapon_categories do
        local category = weapon_categories[i];
        local settings = options[category];

        local global_enabled = current_category == i


        local enabled_dyn = settings.dyn_fov:get();

        settings.hitbox:set_visible(global_enabled and enabled_rage);
        settings.aim_fov:set_visible(global_enabled and enabled_rage and not enabled_dyn);
        settings.dyn_fov:set_visible(global_enabled and enabled_rage);
        settings.max_dyn_fov:set_visible(global_enabled and enabled_rage and enabled_dyn);
        settings.min_dyn_fov:set_visible(global_enabled and enabled_rage and enabled_dyn);
        settings.comp_recoil:set_visible(global_enabled and enabled_rage);
        settings.comp_recoil_x:set_visible(global_enabled and enabled_rage and settings.comp_recoil:get());
        settings.comp_recoil_y:set_visible(global_enabled and enabled_rage and settings.comp_recoil:get());
        settings.comp_after:set_visible(global_enabled and enabled_rage and settings.comp_recoil:get());

        settings.trigger_enable:set_visible(global_enabled);
    end

    weapons:set_visible(enabled_rage and not global_only);
    use_only_global:set_visible(enabled_rage)
end

function console_log(text)
    print("[Kitkat] ".. text);
end 


console_log("legitbot loaded")
console_log("thanks for using the script")
console_log("if you have any questions or suggestions, contact me on discord:satou#4430 or on the primordial forums")

callbacks.add(e_callbacks.SETUP_COMMAND, on_setup_command);
callbacks.add(e_callbacks.DRAW_WATERMARK, on_paint)
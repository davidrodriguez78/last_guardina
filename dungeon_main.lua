---------------------------------
-- the dungeon (segundo cart)
---------------------------------
--usa los archivos compartidos:
--player.lua, ui.lua, rooms.lua
--lo propio de las mazmorras va en dungeon_entities.lua

function _init()
    iplr()
    i_ui()
    hud_sword=85  --en esta hoja la espada esta en el 85
    --datos que manda el primer cart:
    --vida,monedas,armadura,espada
    local d=split(stat(6))
    if d[4] then
        plr.life=d[1]
        plr.cash=d[2]
        plr.armor=d[3]
        plr.sword=d[4]==1
    else
        --probando este cart solo
        plr.armor=1
        plr.sword=true
    end
    --primer room de las mazmorras
    room_x=0
    room_y=3
    room_w=16
    room_h=16
    plr.x=24
    plr.y=96
    game_state="play"
    shake=0
end

function _update60()
    --el temblor se va apagando
    shake=shake>0.3 and shake*0.85 or 0
    if game_state=="play" then
        uplr()
        u_ui()
        by_room()
    elseif game_state=="scroll" then
        u_scroll()
    elseif game_state=="fade" then
        u_fade()
    elseif game_state=="int" then
        u_dlg()
    elseif game_state=="over" then
        --reiniciar (con los datos con los que entraste)
        if btnp(4) then _init() end
    end
end

function _draw()
    cls()
    if game_state=="scroll" then
        d_scroll()
    else
        camera(rnd(shake*2)-shake,rnd(shake*2)-shake)
        map(room_x*16,room_y*16,0,0,room_w,room_h)
        d_ent()
        dplr()
    end
    camera()
    d_ui()

    --debug
    print("room: "..room_x..","..room_y,0,120,7)

    if game_state=="over" then
        rectfill(24,52,103,75,0)
        rect(24,52,103,75,8)
        print("game over",46,57,8)
        print("\x8e restart",38,66,7)
    end
    if game_state=="fade" then
        d_fade()
    end
end

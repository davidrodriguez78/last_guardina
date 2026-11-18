function _init()
    iplr()
    i_ent()
    i_ui()
    --room
    room_x=0
    room_y=0
    room_w=16
    room_h=16
    --game state
    game_state="play"
    shake=0
end

function _update60()
    --el temblor se va apagando
    shake=shake>0.3 and shake*0.85 or 0
    --el fuego se anima siempre (tambien en dialogos)
    if game_state!="fade" then u_fire() end
    if game_state=="play" then
        uplr()
        u_ui()
        by_room()
        if game_state=="play" then u_ent() end
    elseif game_state=="scroll" then
        u_scroll()
    elseif game_state=="fade" then
        u_fade()
    elseif game_state=="int" then
        u_dlg()
    elseif game_state=="over" then
        --reiniciar
        if btnp(4) then _init() end
    end
end

function _draw()
    cls()
    if game_state=="scroll" then
        d_scroll()
    else
        --screen shake: mueve la camara al azar
        camera(rnd(shake*2)-shake,rnd(shake*2)-shake)
        map(room_x*16,room_y*16,0,0,room_w,room_h)
        d_ent()
        dplr()
    end

    --stats--
    camera()
    d_ui()

    --debug
    print("room: "..room_x..","..room_y,0,120,7)
    --print("x "..plr.x..",".."y "..plr.y,plr.x,plr.y-8,10)

    --game over
    if game_state=="over" then
        rectfill(24,52,103,75,0)
        rect(24,52,103,75,8)
        print("game over",46,57,8)
        print("🅾️ restart",38,66,7)
    end

    --fundido (oscurece toda la pantalla)
    if game_state=="fade" then
        d_fade()
    end
end

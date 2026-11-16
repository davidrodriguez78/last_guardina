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
        if btnp(4) or btnp(5) then _init() end
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
        print("\x8e/\x97 restart",38,66,7)
    end

    --fundido (oscurece toda la pantalla)
    if game_state=="fade" then
        d_fade()
    end
end

--room
--si el player sale por un borde, empieza el scroll
function by_room()
    if plr.x>120 then
        start_scroll(1,0)
    elseif plr.x<0 then
        start_scroll(-1,0)
    elseif plr.y>120 then
        start_scroll(0,1)
    elseif plr.y<0 then
        start_scroll(0,-1)
    end
end

---------------------------------
-- transicion entre rooms
---------------------------------
scroll_dur=40  --frames que dura (128px / 40 = 3.2px por frame)

--dx,dy: direccion (-1,0,1)
function start_scroll(dx,dy)
    sc={
        dx=dx, dy=dy, t=0,
        ox=room_x, oy=room_y,      --room de donde vienes
        --player: de donde sale (en coords del room nuevo)
        sx=plr.x-dx*128, sy=plr.y-dy*128,
        --a donde llega (igual que antes: x=1 / x=120...)
        tx=plr.x, ty=plr.y
    }
    if dx==1 then sc.tx=1 end
    if dx==-1 then sc.tx=120 end
    if dy==1 then sc.ty=1 end
    if dy==-1 then sc.ty=120 end
    --el room nuevo ya es el actual
    room_x+=dx
    room_y+=dy
    --prepara enemigos/botin del room nuevo
    on_room_change()
    game_state="scroll"
end

function u_scroll()
    sc.t+=1
    local p=sc.t/scroll_dur
    --el player camina un poco mientras se mueve la pantalla
    plr.x=sc.sx+(sc.tx-sc.sx)*p
    plr.y=sc.sy+(sc.ty-sc.sy)*p
    anim()
    if sc.t>=scroll_dur then
        plr.x=sc.tx
        plr.y=sc.ty
        game_state="play"
    end
end

function d_scroll()
    local p=sc.t/scroll_dur
    --camara del room nuevo: empieza fuera de pantalla
    local cx=(p-1)*128*sc.dx
    local cy=(p-1)*128*sc.dy
    --room viejo (se va)
    camera(cx+sc.dx*128,cy+sc.dy*128)
    map(sc.ox*16,sc.oy*16,0,0,16,16)
    --room nuevo (entra) con sus cosas
    camera(cx,cy)
    map(room_x*16,room_y*16,0,0,16,16)
    d_ent()
    dplr()
    camera()
end

---------------------------------
-- fundido a negro (puertas)
---------------------------------
fade_dur=16  --frames de cada mitad (oscurecer / aclarar)

--cada color se vuelve el de esta tabla (uno mas oscuro)
dark={[0]=0,0,1,1,2,1,5,6,2,4,9,3,1,1,2,4}

function start_fade(d)
    fd={d=d, t=0}
    plr.state="idle"
    plr.sp=1
    game_state="fade"
end

function u_fade()
    fd.t+=1
    --en negro total: cambiar de room
    if fd.t==fade_dur then
        local d=fd.d
        if d.seal then seal_barrier(barriers[d.seal]) end
        room_x=d.to_rx
        room_y=d.to_ry
        plr.x=d.to_x
        plr.y=d.to_y
        on_room_change()
    end
    if fd.t>=fade_dur*2 then
        pal()
        game_state="play"
    end
end

function d_fade()
    --nivel de oscuridad: 0 (normal) a 5 (negro)
    local t=fd.t
    if t>fade_dur then t=fade_dur*2-t end
    local lvl=flr(t/fade_dur*5+0.5)
    for c=0,15 do
        local n=c
        for i=1,lvl do n=dark[n] end
        pal(c,n,1)
    end
end

--temblor de pantalla (n = fuerza en pixeles)
function add_shake(n)
    shake=max(shake,n)
end

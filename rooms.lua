---------------------------------
-- rooms, scroll, fundido, temblor
-- (compartido por todos los carts)
---------------------------------
--cada cart tiene que definir:
--  on_room_change()  al entrar a un room nuevo
--  d_ent()           dibujar las cosas del room

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

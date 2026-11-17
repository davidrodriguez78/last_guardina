function iplr()
    plr={
        sp=1,
        x=7*8,
        y=8*8,
        dx=0,
        dy=0,
        w=12,
        h=12,
        flp=false,
        spd=1,
        state="idle",
        dir="left",
        sword=false,
        armor=0,   --0=sin armadura 1=soldier 2=commander 3=hero
        talis=false,
        keys=false,
        life=100,
        cash=0,
        inv=0,     --frames invulnerable tras recibir dano
        kt=0,      --frames de empujon
        kx=0,
        ky=0
    }
    shadow={sp=66}
    sword={}
    anim_timer=0
    attac_t=0
end

function uplr()
    local lx=plr.x
    local ly=plr.y
    if plr.inv>0 then plr.inv-=1 end
    --empujado por un enemigo: sin control
    if plr.kt>0 then
        plr.kt-=1
        --las puertas (flag 1) tambien frenan el empujon
        --si no, el player queda metido en la puerta y no se puede mover
        plr.x=mid(0,plr.x+plr.kx,120)
        if is_solid() or touch_flag(1) then plr.x=lx end
        plr.y=mid(0,plr.y+plr.ky,120)
        if is_solid() or touch_flag(1) then plr.y=ly end
        plr.kx*=0.8
        plr.ky*=0.8
        return
    end
    --atack state
    if plr.state=="attack" then
        attac()
        return
    end
    if btn(0) then
        plr.dir="left"
        plr.dx= -plr.spd
        plr.flp=false
        plr.state="walk"
    elseif btn(1) then
        plr.dir="right"
        plr.dx=plr.spd
        plr.flp=true
        plr.state="walk"
    else
        plr.dx=0
    end
    if btn(2) then
        plr.dy= -plr.spd
        plr.dir="up"
        plr.state="walk"
    elseif btn(3) then
        plr.dy=plr.spd
        plr.dir="down"
        plr.state="walk"
    else
        plr.dy=0
    end
    --vec norm
    if plr.dx!=0 and plr.dy!=0 then
        plr.dx*=0.7071
        plr.dy*=0.7071
    else
        plr.x=flr(plr.x+0.5)
        plr.y=flr(plr.y+0.5)
        --si al redondear se mete en un muro, no redondear
        if is_solid() then
            plr.x=lx
            plr.y=ly
        end
    end
    --movement + collision por ejes
    --(asi se desliza por los muros)
    plr.x+=plr.dx
    if is_solid() then plr.x=lx end
    plr.y+=plr.dy
    if is_solid() then plr.y=ly end
    --anim
    if plr.dx!=0 or plr.dy!=0 then
        plr.state="walk"
        anim()
    else
        plr.state="idle"
        plr.sp=1
        anim_timer=0
    end

    --attac input
    if plr.sword then
        if btnp(5)  and plr.state!="attack"then
            plr.state="attack"
            plr.sp=11
            attac_t=4
            plr.dx=0
            plr.dy=0
        end
    end
    --old men
    old_men.near=false
    if old_men.rx==room_x and old_men.ry==room_y then
        --el viejo es solido
        if interact(old_men.x,old_men.y,old_men.w,old_men.h) then
            plr.x=lx
            plr.y=ly
        end
        --cerca del viejo? (zona un poco mas grande)
        if interact(old_men.x-3,old_men.y-3,old_men.w+6,old_men.h+6) then
            old_men.near=true
            if btnp(4) then
                talk_old()
            end
        end
    end
    --cofres (son solidos)
    if u_chests() then
        plr.x=lx
        plr.y=ly
    end
    --entradas (cuevas, casas, etc)
    if check_doors() then
        plr.x=lx
        plr.y=ly
    end

end

function dplr()
    --plr
    --spr(shadow.sp,plr.x,plr.y+9,2,1)
    --parpadea mientras es invulnerable
    if plr.inv%8>=4 then return end
    spr(plr.sp,plr.x,plr.y,2,2,plr.flp)
end

--armaduras
--def: cuanto dano quita (0.25 = 25% menos)
--atk: dano de la espada con esa armadura
--ui:  sprites del hud (casco, pecho, botas)
--commander y hero: cambiar sprites cuando existan
armors={
    {name="soldier",   def=0.25, atk=1, ui={84,96,121}},
    {name="commander", def=0.5,  atk=2, ui={84,96,121}},
    {name="hero",      def=0.75, atk=3, ui={84,96,121}},
}

--dar armadura (solo si es mejor que la actual)
function give_armor(lvl)
    plr.armor=max(plr.armor,lvl)
end

--dano de la espada (sube con cada armadura)
function plr_atk()
    if plr.armor>0 then return armors[plr.armor].atk end
    return 1
end

--el player recibe dano
--ox,oy: desde donde viene el golpe
function hurt_plr(dmg,ox,oy)
    if plr.inv>0 or game_state!="play" then return end
    if plr.armor>0 then
        dmg=max(1,flr(dmg*(1-armors[plr.armor].def)))
    end
    plr.life=max(0,plr.life-dmg)
    add_shake(2)
    plr.inv=60
    --cancela el ataque
    plr.state="idle"
    plr.sp=1
    --empujon hacia atras
    local dx=plr.x+7-ox
    local dy=plr.y+7-oy
    local d=max(sqrt((dx/4)^2+(dy/4)^2)*4,1)
    plr.kx=dx/d*2.5
    plr.ky=dy/d*2.5
    plr.kt=10
    if plr.life<=0 then
        game_state="over"
    end
end

function anim()
    if anim_timer<=0 then
        plr.sp+=2
        if plr.sp>=10 then
            plr.sp=3
        end
        anim_timer=8
    end
    anim_timer-=1

end

--toca el player algun tile con este flag?
function touch_flag(flg)
    local mx1=room_x*16+flr((plr.x+3)/8)
    local mx2=room_x*16+flr((plr.x+plr.w)/8)
    local my1=room_y*16+flr((plr.y+2)/8)
    local my2=room_y*16+flr((plr.y+plr.h+1)/8)

    return fget(mget(mx1,my1),flg)
        or fget(mget(mx2,my1),flg)
        or fget(mget(mx1,my2),flg)
        or fget(mget(mx2,my2),flg)
end

--collision
function is_solid()
    return touch_flag(0)
end

function attac()
    if attac_t<=0 then
        plr.sp+=2

        if plr.sp>13 then
            plr.state="idle"
            plr.sp=1
            return
        end
        attac_t=4
    end
    attac_t-=1
end

function interact(objx,objy,objw,objh)
    return plr.x+3<objx+objw and
            plr.x+plr.w>objx and
            plr.y<objy+objh and
            plr.y+plr.h>objy
end

--entradas
--rx,ry:   room donde esta la entrada
--flg:     flag del tile de la entrada
--to_rx/ry: room destino
--to_x/y:  donde aparece el player
--need:    (opcional) item de plr requerido
--          ej: "keys", "talis", "sword"
--lock:    (opcional) nombre de la barrera que la bloquea
--seal:    (opcional) barrera que se cierra para siempre al usarla
doors={
    --entrada cueva (bloqueada por la barrera)
    {rx=7,ry=0,flg=1, to_rx=6,to_ry=2, to_x=62,to_y=20, lock="cave_in"},
    --salida cueva (bloqueada hasta matar a todos)
    {rx=6,ry=2,flg=1, to_rx=7,to_ry=0, to_x=62,to_y=28, lock="cave_out", seal="cave_in"},
    --ejemplo cueva bloqueada:
    --{rx=3,ry=1,flg=1, to_rx=5,to_ry=3, to_x=56,to_y=100, need="keys"},
}

--devuelve true si la puerta esta bloqueada
function check_doors()
    for d in all(doors) do
        if d.rx==room_x and d.ry==room_y
        and touch_flag(d.flg) then
            if d.need and not plr[d.need] then
                return true --bloqueada
            end
            if d.lock and barriers[d.lock].on then
                return true --barrera activa
            end
            --fundido a negro y luego cambia de room
            start_fade(d)
            return true
        end
    end
    return false
end

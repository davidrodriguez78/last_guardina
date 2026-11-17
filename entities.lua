function i_ent()
    old_men={
        x=4*8,
        y=7*8,
        rx=0,
        ry=0,
        w=8,
        h=16,
        sp=16,
        talked=false,
        near=false
    }
    i_enemies()
    i_loot()
    i_spikes()
    i_barriers()
    i_fire()
    i_castle()
end

function u_ent()
    u_enemies()
    u_loot()
    u_spikes()
    u_barriers()
    u_castle()
end

function d_ent()
    d_fire()
    --old
    if old_men.rx==room_x and old_men.ry==room_y then
        spr(old_men.sp,old_men.x,old_men.y,1,2)
        --aviso de "pulsa o" encima del viejo
        if old_men.near and game_state=="play" then
            print("\x8e",old_men.x,old_men.y-7,7)
        end
    end
    d_loot()
    d_barriers()
    d_castle()
    d_enemies()
    d_txts()
end

--dialogo del viejo
function talk_old()
    if not old_men.talked then
        start_dlg({
            "the king has been\ncaptured...",
            "take this sword and\nthis armor.",
            "getting him back\nwon't be easy."
        },function()
            --al terminar la primera charla
            old_men.talked=true
            plr.sword=true
            give_armor(1) --soldier armor
        end)
    else
        start_dlg({"good luck!"})
    end
end

---------------------------------
-- enemigos
---------------------------------

--tipos de enemigo
--frames: sprites de la animacion
--spd:    velocidad persiguiendo
--fly:    true = flota (ignora muros)
--aspd:   frames entre fotogramas
--hp:     vida (la espada quita atk de la armadura)
--col:    color de la explosion al morir
--coin:   probabilidad de soltar moneda (0-1)
--bag:    probabilidad de soltar bolsa (0-1)
--dmg:    dano que hace al player (vida max 100)
etypes={
    {name="slime", frames={104,105,106,105}, spd=0.35, aspd=10, hp=4, col=12, dmg=12, coin=0.5, bag=0.1},
    {name="worm",  frames={107,108},         spd=0.25, aspd=14, hp=2, col=14, dmg=10, coin=0.4, bag=0.05},
    {name="flyeye",frames={109},             spd=0.55, fly=true, hp=4, col=11, dmg=15, coin=0.6, bag=0.15},
    {name="skull", frames={110},             spd=0.45, fly=true, hp=6, col=7, dmg=20, coin=0.6, bag=0.25},
}

knock=2.5   --fuerza del empujon al golpear

aggro_r=40   --distancia a la que te ven
lose_r=72    --distancia a la que dejan de seguirte
resp_t=15    --segundos fuera del room para que reaparezcan

--spawns: tipo,room_x,room_y,tile_x,tile_y
--tipo: 1=slime 2=worm 3=flyeye 4=skull
spawns="1,1,0,5,5,1,1,0,8,11,1,2,0,6,4,2,2,0,10,8,3,2,0,12,4,2,3,0,3,4,1,3,0,10,4,2,3,0,9,9,3,4,0,6,4,1,4,0,10,7,2,4,0,4,9,2,5,0,7,4,2,5,0,9,7,1,6,0,4,4,1,6,0,10,8,3,6,0,7,12,3,7,0,5,5,4,7,0,11,10,1,0,1,11,3,2,0,1,5,7,1,0,1,7,13,2,1,1,6,5,1,1,1,10,10,3,1,1,12,4,1,2,1,5,4,1,2,1,9,10,2,2,1,12,12,2,3,1,3,5,3,3,1,11,5,1,3,1,10,13,1,4,1,3,5,2,4,1,11,5,1,4,1,12,12,3,5,1,4,4,1,5,1,8,8,2,5,1,12,12,1,6,1,5,5,1,6,1,10,10,3,6,1,12,4,2,7,1,1,10,3,7,1,7,6,4,0,2,4,8,2,0,2,11,4,1,1,2,6,3,2,1,2,5,9,4,1,2,13,13,2,2,2,3,4,4,2,2,12,3,1,2,2,8,13,4,3,2,5,3,3,3,2,10,4,1,3,2,8,13,2,4,2,3,4,4,4,2,12,4,1,4,2,10,13,4,5,2,6,4,3,5,2,11,9,2,5,2,5,12,4,6,2,2,5,4,6,2,13,8,3,6,2,11,9,4,7,2,5,4,4,7,2,11,5,2,7,2,4,11,4,0,3,9,4,3,0,3,5,8,2,0,3,10,12,1,1,3,5,3,2,1,3,7,8,3,1,3,10,13,3,2,3,2,5,4,2,3,10,1,1,2,3,2,9,2,3,3,6,5,4,3,3,11,9,1,3,3,8,13,1,4,3,4,4,2,4,3,10,13,3,4,3,14,12,4,5,3,5,5,4,5,3,10,10,3,5,3,7,12,2,6,3,5,3,4,6,3,8,9,3,6,3,11,13,4,7,3,4,4,4,7,3,11,4,2,7,3,11,11"

function i_enemies()
    enemies={}
    room_left={}  --cuando saliste de cada room
    local d=split(spawns)
    for i=1,#d,5 do
        local e={
            typ=etypes[d[i]],
            rx=d[i+1], ry=d[i+2],
            hx=d[i+3]*8, hy=d[i+4]*8,  --posicion de casa
            ph=rnd()                   --desfase para flotar
        }
        reset_enemy(e)
        add(enemies,e)
    end
    prv_rx=room_x or 0
    prv_ry=room_y or 0
    fx={}  --efectos de muerte
end

--vuelve a su sitio y revive
function reset_enemy(e)
    e.x=e.hx
    e.y=e.hy
    e.dead=false
    e.chase=false
    e.fr=1
    e.at=0
    e.flp=false
    e.hp=e.typ.hp
    e.inv=0    --frames invulnerable tras un golpe
    e.stun=0   --frames empujado (no persigue)
    e.kx=0
    e.ky=0
end

function in_room(e)
    return e.rx==room_x and e.ry==room_y
end

--matar enemigo (lo usaremos con la espada)
function kill_enemy(e)
    e.dead=true
    add(fx,{x=e.x+4,y=e.y+4,t=0,col=e.typ.col})
    enemy_drop(e)
    add_shake(1)
end

--zona que golpea la espada
--el sprite mira a la izquierda por defecto
function sword_box()
    local x=plr.x-4
    if plr.flp then x=plr.x+8 end
    return x,plr.y+1,12,14
end

--golpear enemigo
function hit_enemy(e,px,py)
    e.hp-=plr_atk()
    e.inv=15
    e.chase=true
    if e.hp<=0 then
        kill_enemy(e)
        return
    end
    --empujon en direccion contraria al player
    local dx=e.x+4-px
    local dy=e.y+4-py
    local d=max(sqrt((dx/4)^2+(dy/4)^2)*4,1)
    e.kx=dx/d*knock
    e.ky=dy/d*knock
    e.stun=12
end

--mueve al enemigo respetando muros
function e_move(e,vx,vy)
    if e.typ.fly then
        e.x+=vx
        e.y+=vy
    else
        --mover por ejes para deslizar por los muros
        if not e_solid(e.x+vx,e.y) then e.x+=vx end
        if not e_solid(e.x,e.y+vy) then e.y+=vy end
    end
    e.x=mid(0,e.x,120)
    e.y=mid(8,e.y,120)
end

--se llama al cambiar de room
function on_room_change()
    --guardamos cuando salimos del room anterior
    room_left[prv_rx..","..prv_ry]=t()
    local left=room_left[room_x..","..room_y]
    local respawn=not left or t()-left>=resp_t
    --en la cueva los enemigos no reaparecen
    if is_cave(room_x,room_y) then respawn=false end
    fx={}
    fire_parts={}
    --se pierde el botin del suelo, menos las pociones
    for d in all(drops) do
        if not d.k.keep then del(drops,d) end
    end
    txts={}
    for e in all(enemies) do
        if in_room(e) then
            if not e.dead then
                --vivos: vuelven a su sitio
                reset_enemy(e)
            elseif respawn then
                --muertos: reaparecen si paso el tiempo
                reset_enemy(e)
            end
        end
    end
    prv_rx=room_x
    prv_ry=room_y
end

--el enemigo choca con un muro?
function e_solid(x,y)
    local ox=room_x*16
    local oy=room_y*16
    for p in all({{1,1},{6,1},{1,6},{6,6}}) do
        if fget(mget(ox+flr((x+p[1])/8),oy+flr((y+p[2])/8)),0) then
            return true
        end
    end
    return false
end

function u_enemies()
    if room_x!=prv_rx or room_y!=prv_ry then
        on_room_change()
    end
    --centro del player
    local px=plr.x+7
    local py=plr.y+7
    local atk=plr.state=="attack"
    local sx,sy,sw,sh=sword_box()
    for e in all(enemies) do
        if in_room(e) and not e.dead then
            if e.inv>0 then e.inv-=1 end
            --la espada toca al enemigo?
            if atk and e.inv<=0
            and sx<e.x+7 and sx+sw>e.x+1
            and sy<e.y+7 and sy+sh>e.y-1 then
                hit_enemy(e,px,py)
            end
            if not e.dead then
                u_enemy(e,px,py)
                --toca al player? (no si esta aturdido)
                if e.stun<=0 and interact(e.x+1,e.y+1,6,6) then
                    hurt_plr(e.typ.dmg,e.x+4,e.y+4)
                end
            end
        end
    end
    --efectos de muerte
    for f in all(fx) do
        f.t+=1
        if f.t>14 then del(fx,f) end
    end
end

function u_enemy(e,px,py)
    local et=e.typ
    --empujado: se mueve hacia atras y no persigue
    if e.stun>0 then
        e.stun-=1
        e_move(e,e.kx,e.ky)
        e.kx*=0.8
        e.ky*=0.8
        return
    end
    local dx=px-(e.x+4)
    local dy=py-(e.y+4)
    --dividimos por 4 para no desbordar
    local dist=sqrt((dx/4)^2+(dy/4)^2)*4

    --detectar / perder al player
    if dist<aggro_r then
        e.chase=true
    elseif dist>lose_r then
        e.chase=false
    end

    --perseguir (se para al tocarte)
    if e.chase and dist>6 then
        local vx=dx/dist*et.spd
        local vy=dy/dist*et.spd
        e_move(e,vx,vy)
        if abs(vx)>0.05 then e.flp=vx<0 end
    end

    --animacion (mas rapida persiguiendo)
    if #et.frames>1 then
        e.at+=1
        local sp=et.aspd
        if not e.chase then sp*=2 end
        if e.at>=sp then
            e.at=0
            e.fr=e.fr%#et.frames+1
        end
    end
end

function d_enemies()
    for e in all(enemies) do
        if in_room(e) and not e.dead then
            local et=e.typ
            local y=e.y
            if et.fly then
                --sombra en el suelo
                ovalfill(e.x+1,e.y+8,e.x+6,e.y+10,1)
                --flotar arriba y abajo
                y+=sin(t()*0.7+e.ph)*2-2
            end
            --parpadeo blanco al recibir golpe
            if e.inv%4>=2 then
                for c=1,15 do pal(c,7) end
            end
            spr(et.frames[e.fr],e.x,y,1,1,e.flp)
            pal()
        end
    end
    --explosion al morir: anillo que crece + chispas
    for f in all(fx) do
        local r=f.t/2
        circ(f.x,f.y,r+1,f.col)
        for i=0,5 do
            local a=i/6+f.t/40
            pset(f.x+cos(a)*r*1.6,f.y+sin(a)*r*1.6,7)
        end
    end
end

---------------------------------
-- monedas, bolsas y cofres
---------------------------------

--tipos de botin: sprite y valor
loot={
    {sp=124, val=1}, --moneda
    {sp=81,  val=5}, --bolsa
    {sp=101, heal=25, keep=true}, --pocion de energia
}
potion_chance=0.5  --probabilidad de pocion en cofres normales
drop_t=600  --frames que dura un botin en el suelo (10s)

--cofres especiales: "room_x,room_y,tile_x,tile_y"
--item: nombre de la variable de plr que se pone a true
--msg:  frases al abrirlo (max 3 lineas cada una)
special_chests={
    ["5,0,9,3"]={item="talis", msg={"you found the\ntalisman!","now you can enter\nthe cave."}},
    ["7,3,14,10"]={item="keys",  msg={"you found\nthe keys!"}},
}

--busca el sprite 122 en el mapa (solo una vez)
--y lo cambia por suelo; el cofre se dibuja aparte
function find_chests()
    chest_spots={}
    for my=0,63 do
        for mx=0,127 do
            if mget(mx,my)==122 then
                --suelo: el vecino que no sea solido
                local fl=mget(mx-1,my)
                for n in all({mget(mx-1,my),mget(mx+1,my),mget(mx,my-1),mget(mx,my+1)}) do
                    if not fget(n,0) and n!=122 then fl=n break end
                end
                mset(mx,my,fl)
                add(chest_spots,{mx,my})
            end
        end
    end
end

function i_loot()
    drops={}
    txts={}  --textos flotantes "+5"
    if not chest_spots then find_chests() end
    chests={}
    for p in all(chest_spots) do
        local rx,ry=p[1]\16,p[2]\16
        local tx,ty=p[1]%16,p[2]%16
        add(chests,{
            rx=rx, ry=ry,
            x=tx*8, y=ty*8,
            cash=5+flr(rnd(11)),  --5 a 15 monedas
            sp=special_chests[rx..","..ry..","..tx..","..ty],
            open=false, near=false
        })
    end
end

--soltar botin al morir
function enemy_drop(e)
    local et=e.typ
    if rnd()<et.bag then
        add_drop(e.x,e.y,2)
    elseif rnd()<et.coin then
        add_drop(e.x,e.y,1)
    end
end

--crea un botin que salta al suelo
function add_drop(x,y,k)
    add(drops,{
        x=x, y=y, z=0,
        rx=room_x, ry=room_y,
        vz=1.5,               --salto hacia arriba
        vx=rnd(1)-0.5,
        k=loot[k],
        t=drop_t
    })
end

--texto flotante
function add_txt(x,y,s,c)
    add(txts,{x=x,y=y,s=s,t=30,c=c or 10})
end

function give_cash(v,x,y)
    plr.cash=min(plr.cash+v,999)
    add_txt(x,y,"+"..v)
end

--hueco libre junto al cofre (abajo, izq, der, arriba)
function chest_side(c)
    for o in all({{0,9},{-9,0},{9,0},{0,-9}}) do
        local x,y=c.x+o[1],c.y+o[2]
        if x>=0 and x<=120 and y>=8 and y<=120
        and not e_solid(x,y) then
            return x,y
        end
    end
    return c.x,c.y+9
end

function u_loot()
    for d in all(drops) do
      if d.rx==room_x and d.ry==room_y then
        --salto con rebote
        d.z+=d.vz
        d.vz-=0.15
        if d.z<=0 then
            d.z=0
            d.vz=-d.vz*0.5
            if d.vz<0.3 then d.vz=0 end
            d.vx=0
        end
        d.x=mid(0,d.x+d.vx,120)
        --las pociones no desaparecen
        if not d.k.keep then d.t-=1 end
        --recoger (cuando ya cayo un poco)
        if d.z==0 and interact(d.x,d.y,8,8) then
            if d.k.heal then
                --pocion: solo si te falta vida
                if plr.life<100 then
                    plr.life=min(100,plr.life+d.k.heal)
                    add_txt(d.x,d.y-4,"+"..d.k.heal,11)
                    del(drops,d)
                end
            else
                give_cash(d.k.val,d.x,d.y-4)
                del(drops,d)
            end
        elseif d.t<=0 then
            del(drops,d)
        end
      end
    end
    for s in all(txts) do
        s.y-=0.4
        s.t-=1
        if s.t<=0 then del(txts,s) end
    end
end

--cofres: se llama desde uplr
--devuelve true si el player choca con un cofre
function u_chests()
    local hit=false
    for c in all(chests) do
        c.near=false
        if c.rx==room_x and c.ry==room_y then
            --el cofre es solido
            if interact(c.x,c.y,8,8) then hit=true end
            --cerca y cerrado? pulsar o para abrir
            if not c.open and interact(c.x-3,c.y-3,14,14) then
                c.near=true
                if btnp(4) then
                    c.open=true
                    if c.sp then
                        --cofre especial: da un objeto
                        plr[c.sp.item]=true
                        start_dlg(c.sp.msg,nil,"chest")
                    else
                        give_cash(c.cash,c.x,c.y-6)
                        --a veces sale una pocion
                        if rnd()<potion_chance then
                            local px,py=chest_side(c)
                            add_drop(px,py,3)
                        end
                    end
                end
            end
        end
    end
    return hit
end

function d_loot()
    --cofres
    for c in all(chests) do
        if c.rx==room_x and c.ry==room_y then
            spr(c.open and 123 or 122,c.x,c.y)
            if c.near and game_state=="play" then
                print("\x8e",c.x,c.y-7,7)
            end
        end
    end
    --botin (parpadea cuando va a desaparecer)
    for d in all(drops) do
        if d.rx==room_x and d.ry==room_y
        and (d.t>120 or d.t%8<4) then
            ovalfill(d.x+1,d.y+6,d.x+6,d.y+8,1)
            spr(d.k.sp,d.x,d.y-d.z)
        end
    end
end

function d_txts()
    for s in all(txts) do
        print(s.s,s.x,s.y,s.c)
    end
end

---------------------------------
-- pinchos
---------------------------------
--117 = pinchos fuera (hacen dano)
--118 = pinchos escondidos (no hacen dano)
spike_on=60    --frames con pinchos fuera
spike_off=60   --frames con pinchos escondidos
spike_dmg=10   --dano al player

--busca los pinchos en el mapa (solo una vez)
function find_spikes()
    spike_spots={}
    for my=0,63 do
        for mx=0,127 do
            local t=mget(mx,my)
            if t==117 or t==118 then
                add(spike_spots,{mx,my})
            end
        end
    end
end

function i_spikes()
    if not spike_spots then find_spikes() end
    spike_t=0
    set_spikes(117)
end

function set_spikes(sp)
    for p in all(spike_spots) do
        mset(p[1],p[2],sp)
    end
end

function u_spikes()
    --animacion: fuera / escondidos
    spike_t+=1
    if spike_t==spike_on then
        set_spikes(118)
    elseif spike_t>=spike_on+spike_off then
        spike_t=0
        set_spikes(117)
    end
    --pies del player sobre un 117?
    for p in all({{4,9},{11,9},{4,13},{11,13}}) do
        local px=plr.x+p[1]
        local py=plr.y+p[2]
        local mx=room_x*16+flr(px/8)
        local my=room_y*16+flr(py/8)
        if mget(mx,my)==117 then
            --empuja desde el centro del pincho
            hurt_plr(spike_dmg,flr(px/8)*8+4,flr(py/8)*8+4)
            return
        end
    end
end

---------------------------------
-- barreras magicas
---------------------------------
--x,y,w,h: zona que tapa (encima de la puerta)
--cols:    colores de las particulas
function i_barriers()
    barriers={
        --entrada de la cueva: se rompe con el talisman
        cave_in={rx=7,ry=0,x=64,y=16,w=16,h=8,on=true,
            cols={12,13,14,2}},
        --salida de la cueva: se abre al matar a todos
        cave_out={rx=6,ry=2,x=64,y=8,w=16,h=8,on=true,
            cols={8,9,10,2}},
    }
    for k,b in pairs(barriers) do
        b.parts={}
        for i=1,24 do
            add(b.parts,new_part(b,b.y+rnd(b.h+4)))
        end
    end
end

--particula que sube desde abajo de la barrera
function new_part(b,y)
    return {
        x=b.x+rnd(b.w),
        y=y or b.y+b.h+2,
        vy=0.2+rnd(0.4),
        c=rnd(b.cols)
    }
end

--volver a cerrar una barrera para siempre
function seal_barrier(b)
    b.on=true
    b.sealed=true
    b.cols={5,6,13,1}  --gris: ya no se puede abrir
end

--romper barrera con explosion de particulas
function break_barrier(b)
    b.on=false
    for i=0,3 do
        add(fx,{x=b.x+2+i*4,y=b.y+4,t=i,col=b.cols[i%#b.cols+1]})
    end
end

--enemigos vivos en un room
--rooms que forman la cueva
cave_rooms={["6,2"]=true,["7,2"]=true,["6,3"]=true,["7,3"]=true}

function is_cave(rx,ry)
    return cave_rooms[rx..","..ry]
end

--enemigos vivos en toda la cueva
function cave_alive()
    local n=0
    for e in all(enemies) do
        if is_cave(e.rx,e.ry) and not e.dead then n+=1 end
    end
    return n
end

function u_barriers()
    local bi=barriers.cave_in
    local bo=barriers.cave_out
    --salida: activa mientras queden enemigos en la cueva
    local n=cave_alive()
    if bo.on and n==0 then
        if room_x==bo.rx and room_y==bo.ry then
            break_barrier(bo)
        else
            bo.on=false
        end
        if is_cave(room_x,room_y) then
            add_txt(30,40,"the exit is open!",11)
        end
    end
    bo.left=n

    --entrada: pulsar o cerca para usar el talisman
    bi.near=false
    if bi.on and room_x==bi.rx and room_y==bi.ry
    and interact(bi.x-4,bi.y,bi.w+8,bi.h+12) then
        bi.near=true
        if btnp(4) then
            if bi.sealed then
                start_dlg({"the cave is\nsealed."},nil,"barrier")
            elseif plr.talis then
                plr.talis=false  --el talisman se gasta
                break_barrier(bi)
                start_dlg({"the talisman breaks\nthe magic barrier!"},nil,"talisman")
            else
                start_dlg({"a magic barrier\nblocks the cave.","you need a\ntalisman."},nil,"barrier")
            end
        end
    end

    --mover particulas
    for k,b in pairs(barriers) do
        if b.on then
            for p in all(b.parts) do
                p.y-=p.vy
                p.x+=sin(t()*2+p.vy*5)*0.2
                if p.y<b.y-3 then
                    del(b.parts,p)
                    add(b.parts,new_part(b))
                end
            end
        end
    end
end

function d_barriers()
    for k,b in pairs(barriers) do
        if b.on and room_x==b.rx and room_y==b.ry then
            --brillo de fondo que parpadea
            if t()%0.5<0.25 then
                fillp(0b1010010110100101.1)
                rectfill(b.x,b.y,b.x+b.w-1,b.y+b.h-1,b.cols[1])
                fillp()
            end
            for p in all(b.parts) do
                pset(p.x,p.y,p.c)
            end
            --aviso
            if b.near and game_state=="play" then
                print("\x8e",b.x+4,b.y+b.h+2,7)
            end
        end
    end
end

---------------------------------
-- fuego (antorchas y fogata)
---------------------------------
--tile: sprite del mapa que tiene fuego
--ox,oy: de donde sale el fuego dentro del sprite
--rate: particulas por frame
--big:  fuego grande (fogata) con chispas y humo
fire_types={
    [111]={ox=4, oy=2, rate=0.4},           --antorcha
    [48] ={ox=8, oy=9, rate=1.5, big=true}, --fogata 16x16
}

--busca los fuegos en el mapa (solo una vez)
function find_fires()
    fire_spots={}
    for my=0,63 do
        for mx=0,127 do
            local ft=fire_types[mget(mx,my)]
            if ft then
                add(fire_spots,{
                    rx=mx\16, ry=my\16,
                    x=mx%16*8+ft.ox, y=my%16*8+ft.oy,
                    ft=ft, acc=0
                })
            end
        end
    end
end

function i_fire()
    if not fire_spots then find_fires() end
    fire_parts={}
end

--se llama siempre (tambien en dialogos)
function u_fire()
    for f in all(fire_spots) do
        if f.rx==room_x and f.ry==room_y then
            local big=f.ft.big
            f.acc+=f.ft.rate
            while f.acc>=1 do
                f.acc-=1
                local w=big and 6 or 2
                add(fire_parts,{
                    x=f.x+rnd(w)-w/2,
                    y=f.y+rnd(2),
                    vx=rnd(0.3)-0.15,
                    vy=-0.3-rnd(big and 0.5 or 0.3),
                    t=0,
                    life=(big and 18 or 10)+rnd(10),
                    big=big
                })
            end
            --chispas de la fogata
            if big and rnd()<0.08 then
                add(fire_parts,{
                    x=f.x+rnd(6)-3, y=f.y,
                    vx=rnd(0.8)-0.4, vy=-1-rnd(0.6),
                    t=0, life=25, spark=true
                })
            end
        end
    end
    for p in all(fire_parts) do
        p.t+=1
        p.x+=p.vx
        p.y+=p.vy
        --se mueve como una llama
        p.x+=sin(p.t/12+p.y/20)*0.15
        if p.t>=p.life then del(fire_parts,p) end
    end
end

function d_fire()
    for p in all(fire_parts) do
        local a=p.t/p.life  --edad 0..1
        if p.spark then
            if a<0.7 or p.t%2==0 then pset(p.x,p.y,10) end
        else
            --color segun la edad: blanco-amarillo-naranja-rojo-humo
            local c=7
            if a>0.15 then c=10 end
            if a>0.35 then c=9 end
            if a>0.6 then c=8 end
            if a>0.8 then c=p.big and 5 or 2 end
            if p.big and a<0.5 then
                --llamas gordas que se encogen
                circfill(p.x,p.y,1.5-a*2,c)
            else
                pset(p.x,p.y,c)
            end
        end
    end
end

---------------------------------
-- puerta del castillo (mazmorras)
---------------------------------
--mx,my: tile de arriba a la izquierda (2x2 tiles)
--closed/open: sprites de la puerta (izq-arriba, der-arriba, izq-abajo, der-abajo)
function i_castle()
    castle={rx=0,ry=0,mx=5,my=1,
        x=40,y=8,w=16,h=16,
        closed={71,72,87,88},
        open={73,74,89,90},
        is_open=false, near=false}
    --al reiniciar vuelve a estar cerrada
    set_castle(castle.closed)
end

--pone los 4 sprites de la puerta en el mapa
function set_castle(sps)
    local c=castle
    mset(c.mx,  c.my,  sps[1])
    mset(c.mx+1,c.my,  sps[2])
    mset(c.mx,  c.my+1,sps[3])
    mset(c.mx+1,c.my+1,sps[4])
end

function open_castle()
    castle.is_open=true
    set_castle(castle.open)
    add_shake(2)
end

--saca al player de la puerta (hacia abajo)
function leave_castle()
    plr.y=castle.y+castle.h+2
end

--entrar a las mazmorras
--todavia no existe el cart de las mazmorras
--cuando exista: load("dungeons.p8")
function enter_dungeon()
    start_dlg({"the dungeons are\nnot ready yet..."},leave_castle,"door")
end

function u_castle()
    local c=castle
    c.near=false
    if room_x!=c.rx or room_y!=c.ry then return end
    if not c.is_open then
        --cerca de la puerta cerrada: o para abrir
        if interact(c.x-2,c.y,c.w+4,c.h+6) then
            c.near=true
            if btnp(4) then
                if plr.keys then
                    open_castle()
                    start_dlg({"the keys open\nthe castle door!"},nil,"door")
                else
                    start_dlg({"the door is\nlocked."},nil,"door")
                end
            end
        end
    --puerta abierta: el player entra en el hueco
    elseif interact(c.x+2,c.y,c.w-4,10) then
        ask_dlg({"you are entering the\ncastle dungeons."},
            enter_dungeon,leave_castle,"door")
    end
end

function d_castle()
    local c=castle
    if c.near and game_state=="play" then
        print("\x8e",c.x+4,c.y+c.h+2,7)
    end
end

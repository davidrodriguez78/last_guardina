---------------------------------
-- dialogos y hud (compartido por todos los carts)
---------------------------------
--cada cart tiene que definir:
--  d_hud()  cosas extra del hud de ese cart
--los sprites del hud tienen que estar en el mismo numero
--en todas las hojas: 80 corazon, 83 espada, 100 moneda,
--82 talisman, 99 llaves, y los de armors (84,96,121)
--la espada usa hud_sword (cada cart puede cambiarlo)

function i_ui()
    --dialogo
    dlg={
        lines={},  --frases
        i=1,       --frase actual
        t=0,       --letras mostradas
        on_end=nil --funcion al cerrar
    }
    helm={
        x=60,
        y=0,
        sp1=84,
        sp2=96,
        sp3=121
    }
    talisman={sp=0}
    hud_sword=83  --sprite de la espada en el hud
end

function u_ui()
    if plr.talis then
        talisman.sp=82
    elseif plr.keys then
        talisman.sp=99
    else
        talisman.sp=0
    end
end

--abre un dialogo
function start_dlg(lines,on_end,name)
    dlg.lines=lines
    dlg.i=1
    dlg.t=0
    dlg.on_end=on_end
    dlg.name=name or "old man"
    dlg.ask=nil
    game_state="int"
end

--dialogo con pregunta: o=no x=si
--la ultima frase muestra las opciones
function ask_dlg(lines,on_yes,on_no,name)
    start_dlg(lines,nil,name)
    dlg.ask={yes=on_yes,no=on_no}
end

--cierra el dialogo y llama a fn
function end_dlg(fn)
    game_state="play"
    if fn then fn() end
end

--se llama en _update60 cuando game_state=="int"
function u_dlg()
    local txt=dlg.lines[dlg.i]
    --escribiendo letra a letra
    if dlg.t<#txt then
        dlg.t+=0.5
        --pulsar o muestra la frase entera
        if btnp(4) then dlg.t=#txt end
        return
    end
    --ultima frase de una pregunta: o=no x=si
    if dlg.ask and dlg.i==#dlg.lines then
        if btnp(4) then end_dlg(dlg.ask.no)
        elseif btnp(5) then end_dlg(dlg.ask.yes) end
        return
    end
    --frase completa: o pasa a la siguiente
    if btnp(4) then
        dlg.i+=1
        dlg.t=0
        if dlg.i>#dlg.lines then
            game_state="play"
            if dlg.on_end then dlg.on_end() end
        end
    end
end

function d_dlg()
    if game_state!="int" then return end
    local txt=dlg.lines[dlg.i]
    --caja
    rectfill(4,92,123,123,1)
    rect(4,92,123,123,7)
    --nombre
    print(dlg.name,8,96,10)
    --texto
    print(sub(txt,1,flr(dlg.t)),8,104,7)
    --indicador parpadeante cuando la frase esta completa
    if dlg.t>=#txt then
        if dlg.ask and dlg.i==#dlg.lines then
            --opciones de la pregunta
            print("\x8e no  \x97 yes",70,116,10)
        elseif t()%1<0.5 then
            print("\x8e",112,116,7)
        end
    end
end

function d_ui()
    --hub--
    rrectfill(0,0,128,8,0,0)
    --extra de cada cart (ej: enemigos de la cueva)
    d_hud()
    --dialogo--
    d_dlg()
    --sword and helm
    if plr.armor>0 then
        local ui=armors[plr.armor].ui
        spr(ui[1],helm.x,helm.y)
        spr(ui[2],helm.x+9,0)
        spr(ui[3],helm.x+18,0)
        spr(hud_sword,88,0)--sword
    end
    --talisman
    --talisman o llaves (nada si no tienes ninguno)
    if talisman.sp>0 then spr(talisman.sp,98,0) end
    
    --coin
    spr(100,108,0)
    print(plr.cash,116,2,7)
    -- ui divide line
    line(87,0,87,7,7)
    line(96,0,96,7,7)
    line(107,0,107,7,7)
    --hearth and life
    rrectfill(8,0,plr.life/2,8,1,8)--red
    rrect(8,0,50,8,1,7)--white
    rectfill(1,0,8,7,0)--rec hearth
    spr(80,0,0)--hearth

end

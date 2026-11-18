---------------------------------
-- cosas de las mazmorras
-- (hooks que piden los archivos compartidos)
---------------------------------
--puertas de las mazmorras (ver check_doors en player.lua)
doors={}

--cosas del room que tocan al player (true = bloquea)
function plr_world()
    return false
end

--al entrar a un room nuevo
function on_room_change()
end

--dibujar las cosas del room (enemigos, cofres...)
function d_ent()
end

--extra del hud
function d_hud()
end

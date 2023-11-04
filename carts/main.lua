-- global arrays
local _bsp,_things,_futures,_spiders,_squid_templates,_cam,_grid,_entities={},{},{},{},{{},{},{}}
-- must be globals
_fire_ttl,_piercing,_hand_pal=3,0,0xd500
local _G,_slow_mo,_ramp_pal=_ENV,0,0x8180

local _vertices,_ground_extents=split[[384.0,0,320.0,
384,0,704,
640,0,704,
640,0,320,
320,0,384,
320,0,640,
384,0,640,
384,0,384,
640,0,384,
640,0,640,
704,0,640,
704,0,384,
384,-32,320,
384,-32,704,
640,-32,704,
640,-32,320,
320,-32,384,
320,-32,640,
384,-32,640,
384,-32,384,
640,-32,384,
640,-32,640,
704,-32,640,
704,-32,384]],
{
  -- xmin/max - ymin/max
  -- with 8 unit buffer simulate player "volume"
  split"312.0,392.0,376.0,648.0",
  split"376.0,648.0,312.0,712.0",
  split"632.0,712.0,376.0,648.0"
}

-- returns a handle to the coroutine
-- used to cancel a coroutine
function do_async(fn)
  return add(_futures,{co=cocreate(fn)})
end
-- wait until timer
function wait_async(t,r)
  -- rnd(nil) returns 0 yeah!
	for i=1,t+rnd(r) do
		yield()
	end
end

-- wait until a certain number of jewels is captured
function wait_jewels(n)
  local prev=_total_jewels
  while _total_jewels<n do
    if _total_jewels!=prev then
      exec[[set;_hw_pal;0x80d0
yield
set;_hw_pal;0x80e0
yield
set;_hw_pal;0x80f0
yield
set;_hw_pal;0x80e0
yield
set;_hw_pal;0x80d0
yield
set;_hw_pal;0x8000
yield]]
    end
    -- update with current total (avoids overlapping "flash" effects)
    prev=_total_jewels
    yield()
  end
  _slow_mo=0
end

function levelup_async(t)
  -- 30 frames at 1/8 steps
  for j=0.125,t<<2,0.125 do
    _ramp_pal=0x8280+((-127*sin(j/(t<<3)))&15)*16
    _slow_mo+=1    
    if(j==t<<1) sfx"43"
    yield()
  end

  -- restore state
  _ramp_pal,_slow_mo=0x8180,0
end

function get_spawn_origin(dist,angle)       
  return v_rnd(512,0,512,dist,angle)
end

-- record number of "things" on playground and wait until free slots are available
-- note: must be called from a coroutine
local _total_things,_total_time,_time_inc
function reserve_async(n)
  while _total_things+n>60 do
    -- stop watch
    _time_inc=0
    yield()
  end
  _time_inc=0x0.0001
  _total_things+=n
end

  -- misc helpers
function with_properties(props,dst)
  local dst,props=dst or {},split(props)
  for i=1,#props,2 do
    local k,v=props[i],props[i+1]
    -- deference
    if tostr(k)[1]=="@" then
      k,v=sub(k,2,-1),_ENV[v]
    elseif k=="ent" then 
      v=_entities[v] 
    else
      local fn=_ENV[v]
      -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      -- note: assumes that function never returns a falsey value
      v=type(fn)=="function" and fn() or v 
    end
    dst[k]=v
  end
  return dst
end

-- grid helpers
-- adds thing in the collision grid
function grid_register(thing)
  local grid,_ENV=_grid,thing
  
  local x,z=origin[1],origin[3]
  -- \32(=5) + >>16
  local x0,x1,z0,z1=(x-radius)>>21,(x+radius)>>21,(z-radius)\32,(z+radius)\32
  -- different from previous range?
  if grid_x0!=x0 or grid_x1!=x1 or grid_z0!=z0 or grid_z1!=z1 then
    -- remove previous grid cells
    grid_unregister(thing)
    for idx=x0,x1,0x0.0001 do
      for idx=idx|z0,idx|z1 do
        local cell=grid[idx]
        cell.things[thing]=true
        -- for fast unregister
        if(not cells) cells={}
        cells[idx]=cell
      end
    end
    -- cache grid coords (keep inline for speed)
    grid_x0=x0
    grid_x1=x1
    grid_z0=z0
    grid_z1=z1

    -- noise emitter?
    if chatter then
      -- \64(=6) + >>16
      local cell=grid[x>>22|z\64]
      cell.chatter[chatter]+=1
      -- for fast unregister
      chatter_cell=cell
    end
  end
end

-- removes thing from the collision grid
function grid_unregister(_ENV)
  for idx,cell in pairs(cells) do
    cell.things[_ENV],cells[idx]=nil
  end  
  if chatter_cell then
    chatter_cell.chatter[chatter]-=1
    chatter_cell=nil
  end    
end

function register_hit(_ENV)  
  -- avoid reentrancy
  if(dead) return
  hp-=1
  if(hit_ttl<3) hit_ttl=5
  return hp<=0
end

-- range index generator
--[[
  done={}

function visit(x0,y0,len)
 local s=""
	for x=x0,x0+len-1 do
	 for y=y0,y0+len-1 do
	 	local idx=(x-x0)>>16|(y-y0)
	 	if not done[x|y<<6] then
	 	 done[x|y<<6]=true
	 	 s..=tostr(idx,1)..","
	 	end
	 end
	end
	return s
end

local s="{{"..visit(2,2,2).."},\n"
s..="{"..visit(1,1,4).."},\n"
s..="{"..visit(0,0,6).."}}"
printh(s,"@clip")
]]
-- concentric offset around player in chatter grid
--  2222
-- 211112
-- 210012
-- 210012
-- 211112
--  2222

function make_player(_origin,_a)
  local _chatter_ranges,on_ground,prev_jump={
    split"0x0,0x0001,0x0.0001,0x0001.0001",
    split"0x0,0x0001,0x0002,0x0003,0x0.0001,0x0003.0001,0x0.0002,0x0003.0002,0x0.0003,0x0001.0003,0x0002.0003,0x0003.0003",
    split"0x0001,0x0002,0x0003,0x0004,0x0.0001,0x0005.0001,0x0.0002,0x0005.0002,0x0.0003,0x0005.0003,0x0.0004,0x0005.0004,0x0001.0005,0x0002.0005,0x0003.0005,0x0004.0005"
  }    
  return inherit(with_properties("tilt,0,radius,24,attract_power,0,dangle,v_zero,velocity,v_zero,eye_pos,v_zero,fire_ttl,0,fire_released,1,fire_frames,0,dblclick_ttl,0,fire,0",{
    -- start above floor
    origin=v_add(_origin,split"0,1,0"), 
    angle={0,_a,0},
    m=make_m_from_euler(angle),
    control=function(_ENV)
      if(dead) return
      -- move
      local dx,dz,a,jmp,jump_down=0,0,angle[2],0,stat(28,@0xc404)
      if(stat(28,@0xc402)) dx=3
      if(stat(28,@0xc403)) dx=-3
      if(stat(28,@0xc400)) dz=3
      if(stat(28,@0xc401)) dz=-3
      if(on_ground and prev_jump and not jump_down) jmp=24 on_ground=false sfx"58"
      prev_jump=jump_down

      -- straffing = faster!

      -- restore atract power
      attract_power=min(attract_power+0.2,1)

      -- double-click detector
      dblclick_ttl=max(dblclick_ttl-1)
      if not btn(@0xc415) then
        sfx(48, -2)
        if not fire_released then
          if dblclick_ttl>0  then
            -- double click timer still active?
            -- shotgun (repulsive!)
            fire_ttl,fire,dblclick_ttl,attract_power=0,2,0,-1
            sfx(29+_piercing, stat"57" and -2 or flr(rnd"4"))
          elseif fire_frames<4 then
            -- candidate for double click?
            dblclick_ttl=8
          end
          fire_released,fire_frames=true,0
        end
      else
        if fire_released then
          fire_released=false
        end
        fire_frames+=1
        -- regular fire      
        if dblclick_ttl==0 and fire_ttl<=0 then
          sfx(48, stat"57" and -2)
          fire_ttl,fire=_fire_ttl,1
        end
        -- 
        attract_power=0
      end

      dangle=v_add(dangle,{$0xc410*stat(39),stat(38),0})
      tilt+=dx/40
      local c,s=cos(a),-sin(a)
      velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx},0.35)                 
    end,
    update=function(_ENV)
      -- damping      
      dangle=v_scale(dangle,0.6)
      -- very slow damping back to normal
      tilt*=0.82
      if(abs(tilt)<=0.0001) tilt=0
      velocity[1]*=0.7
      --velocity[2]*=0.9
      velocity[3]*=0.7
      -- gravity
      velocity[2]-=0.8
      
      -- avoid overflow!
      fire_ttl=max(fire_ttl-1)

      angle=v_add(angle,dangle,$0xc416/1024)
      -- limit x amplitude
      angle[1]=mid(angle[1],-0.24,0.24)
      -- check next position
      local vn,vl=v_normz(velocity)      
      local prev_pos,new_pos,new_vel=v_clone(origin),v_add(origin,velocity),velocity
      if vl>0.1 then
          local x,y,z=unpack(new_pos)
          if y<-64 then
            y=-64
            new_vel[2]=0
            if not dead then
              dead=true
              next_state(gameover_state,"FLOORED")
            end
          elseif y<0 then
            -- main grid?              
            local out=0
            for _,extent in pairs(_ground_extents) do
              if x<extent[1] or x>extent[2] or z<extent[3] or z>extent[4] then
                out+=1
              end
            end
            -- missed all ground chunks?
            if out!=#_ground_extents then
              -- stop velocity
              y=0
              new_vel[2]=0
              on_ground=true
            end
          end
          -- use corrected velocity
          origin,velocity={x,y,z},new_vel
      end

      eye_pos=v_add(origin,{0,18,0})

      -- check collisions
      local x,z=origin[1],origin[3]
      if not dead then   
        local vn,vl=v_normz{velocity[1],0,velocity[3]}
        -- for hand effect
        xz_vel=vl
        -- 
        collect_grid(prev_pos,origin,vn[1],vn[3],function(grid_cell)
          -- avoid reentrancy
          if(dead) return
          for thing in pairs(grid_cell) do
            if not thing.dead then
              -- special handling for crawling enemies
              local dist=v_len(thing.on_ground and origin or eye_pos,thing.origin)
              if dist<thing.radius then
                if thing.pickup then
                  thing:pickup()
                else
                  -- avoid reentrancy
                  dead=true
                  next_state(gameover_state,thing.obituary)
                  return
                end
              end
            end
          end
        end)
      end

      --chatter stats
      local _ambient,_chatter,_chattered,_chattermax=true,{},0,3
      for i=46,49 do
        local cur_sfx = stat(i)

        if cur_sfx>28 then
          --reduce available channels
          _chattermax-=1
        elseif cur_sfx>7 then
          --record chatter_id
          _ambient,_chatter[cur_sfx-cur_sfx%4]=false,true
        end
      end

      --chatter playback
      if _chattermax > 0 and not stat"57" then
        local x0,z0=x>>22,z\64
        for dist,offsets in inext,_chatter_ranges do
          local idx=x0|z0
          for _,idx_offset in inext,offsets do
            local cell=_grid[idx+idx_offset]
            for chatter_id,cnt in pairs(cell.chatter) do
              --queue new chatter
              if cnt>0 and not _chatter[chatter_id] then
                local variant=chatter_id+flr(rnd"4")
                local offset=variant*68

                --copy dampened sfx, start at 0xf010-0x220 to offset sfx 0-7
                memcpy(0x3200+offset, 0xedf0+0x550*(dist-1)+offset, 68)
                sfx(variant)

                _ambient,_chatter[chatter_id]=false,true
                _chattered += 1

                if(_chattered>=_chattermax) goto end_noise
              end
            end
          end
          -- next range
          x0-=0x0.0001
          z0-=1
        end

        if(_ambient) sfx"28"
      end
::end_noise::

      -- refresh angles
      m=make_m_from_euler(unpack(angle))    

      -- normal fire
      local o=v_add(origin,v_add({0,8,0},v_add(m_fwd(m),m_right(m)),4))
      if fire==1 then          
        _G._total_bullets+=0x0.0001
        make_bullet(o,angle[2],angle[1],0.02)
      elseif fire==2 then
        -- shotgun
        _G._total_bullets+=_shotgun_count>>16
        for i=1,_shotgun_count do
          make_bullet(o,angle[2],angle[1],_shotgun_spread)
        end
      end
      fire=nil          
    end
  }))
end

local _checked=0
function vector_in_cone(zangle,yangle,spread)
  local zangle,yangle=0.25-zangle+rrnd(spread),yangle+rrnd(spread)
  local u,v,s=cos(zangle),-sin(zangle),cos(yangle)
  return {s*u,sin(yangle),s*v},u,v,sgn(s),zangle,yangle
end

function make_bullet(_origin,_zangle,_yangle,_spread)
  -- no bullets while falling
  if(_origin[2]<2) return

  local _velocity,_u,_v,_s,_zangle=vector_in_cone(_zangle,_yangle,_spread)
  add(_things,inherit({
    origin=v_clone(_origin),
    -- must be a unit vector  
    velocity=_velocity,
    -- fixed zangle
    zangle=_zangle,
    yangle=rnd(),
    -- 2d unit vector
    -- precomputed for collision detection
    -- make sure to keep the sign of the y component!!
    u=_s*_u,
    v=_s*_v,
    piercing=_piercing,
    shadeless=true,
    ttl=time()+0.5+rnd"0.1",
    ent=rnd{_entities.dagger0,_entities.dagger1},
    physic=function(_ENV)
      if ttl<time() then
        dead=true
      else
        _checked+=1
        yangle+=0.1
        local cur_origin,new_origin,len=origin,v_add(origin,velocity,10),10
        local x,y,z=unpack(new_origin)
        if y<0 then
          -- hit ground?
          -- intersection with ground
          local dy=cur_origin[2]/(cur_origin[2]-y)
          x,y,z=lerp(cur_origin[1],x,dy),0,lerp(cur_origin[3],z,dy)
          new_origin={x,0,z}
          -- adjust length
          len*=dy
          -- no matter what - we hit the ground!
          dead=true
          -- sparkles
          for i=1,rnd"5" do
            local vel,u,v=vector_in_cone(0.25-zangle,yangle,0.03)
            make_particle(_dagger_hit_template,new_origin,v_scale(vel,1+rnd()))
          end
        end
        -- collect touched grid indices
        -- advanced bullets can traverse enemies
        local hits={}
        collect_grid(cur_origin,new_origin,u,v,function(things)
          for thing in pairs(things) do
            -- hitable?
            -- avoid checking the same enemy twice
            if not thing.dead and thing.hit and thing.checked!=_checked then
              thing.checked=_checked
              -- segment (a->b)/sphere(origin,r) intersection
              -- o_offset: y offset to origin (useful for squids)
              -- returns distance to target
              -- note: no need to scale down as check is done per 32x32 region
              local o=thing.origin
              -- slightly inflate collision radius (dagger)
              local r,dx,dy,dz,ax,ay,az,oy=thing.radius+2,velocity[1],velocity[2],velocity[3],cur_origin[1],cur_origin[2],cur_origin[3],o[2]+(thing.o_offset or 0)
              -- projection on ray
              local mx,my,mz,ny=ax-o[1],ay-oy,az-o[3],y-oy
              if((my<-r and ny<-r) or (my>r and ny>r)) goto continue
              local b,c=dx*mx+dy*my+dz*mz,mx*mx+my*my+mz*mz-r*r
              if(c>0 and b>0)  goto continue
              local disc=b*b-c
              if(disc<0)  goto continue
              local t=-b-sqrt(disc)
              -- far away?
              if(t>len) goto continue
              -- inside radius?
              if(t<0) t=rnd(len)
              local inserti=#hits+1
              -- basic insertion sort
              for i,prev_hit in inext,hits do          
                if(prev_hit[1]>t) inserti=i break
              end
              add(hits,{t,function() 
                local pos={ax+t*dx,ay+t*dy,az+t*dz}
                thing:hit(pos,_ENV) 
                _G._total_hits+=0x0.0001 
                -- "hard" object
                if(thing.hit==nop) piercing=-1
                -- todo: piercing effect?
                -- if(piercing>0) make_particle(_dagger_hit_template,pos,velocity)
              end},inserti)
::continue::
            end
          end
        end)
        -- apply hit on closest thing        
        if #hits>0 then          
          for i,hit in inext,hits do            
            hit[2]()
            piercing-=1
            if(piercing<0) dead=true break
          end
        end
        origin=new_origin
      end      
    end
  }))
end

function draw_grid(cam)
  local things,m,cx,cy,cz={},cam.m,unpack(cam.origin)
  -- make sure camera matrix is local
  local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]

  -- clear shadows
	-- draw shadows
  exec[[_map_display;1
poke;0x5f54;0x00;0x60
poke;0x5f5e;0b00001000
rectfill;0;0;127;127;0
poke;0x5f5e;0b10001000]]

  -- project
  for i,obj in inext,_things do
    local origin=obj.origin  
    local oy=origin[2]
    -- centipede can be below ground...
    if oy>=1 then
      if not obj.shadeless then
        local sx,sy=origin[1]/3-0x6a.aaaa,origin[3]/3-0x6a.aaaa
        circfill(sx,sy,(obj.s_radius or obj.radius)/3,4)
      end
      if not obj.no_render then
        local x,y,z=origin[1]-cx,origin[2]-cy,origin[3]-cz
        local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
        local az4=az<<2
        if az>4 and az<192 and ax<az4 and -ax<az4 and ay<az4 and -ay<az4 then
          local w=32/az
          things[#things+1]={key=w,thing=obj,x=63.5+ax*w,y=63.5-ay*w}      
        end
      end
    end
  end
  -- default transparency
  exec[[poke;0x5f5e;0xff
poke;0x5f54;0x60;0x00
_map_display;0
poke;0x5f0f;0x1f
poke;0x5f00;0x00]]

  -- radix sort
  rsort(things)

  -- render in order
  local prev_base,prev_sprites,pal0
  for _,item in inext,things do
    local thing=item.thing
    local hit_ttl,pal1=thing.hit_ttl
    if hit_ttl and hit_ttl>0 then
      pal1=min(hit_ttl<<1,8)-9
    else      
      pal1=min(15,(item.key*(thing.bright or 1))<<4)\1
    end    
    if(pal0!=pal1) memcpy(0x5f00,_ramp_pal+(pal1<<4),16) palt(15,true) pal0=pal1   
    -- draw things
    local w0,entity,origin=item.key,thing.ent,thing.origin
    -- zangle (horizontal)
    local dx,dz,yangles,side,flip=cx-origin[1],cz-origin[3],entity.yangles,0
    local zangle=atan2(dx,-dz)
    if yangles!=0 then
      local step=1/(yangles<<1)
      side=((zangle-thing.zangle+0.5+step/2)&0x0.ffff)\step
      if(side>yangles) side=yangles-(side%yangles) flip=true
    end

    -- up/down angle
    local zangles,yside=entity.zangles,0
    if zangles!=0 then
      local yangle,step=thing.yangle or 0,1/(zangles<<1)
      yside=((atan2(dx*cos(-zangle)+dz*sin(-zangle),-cy+origin[2])-0.25+step/2+yangle)&0x0.ffff)\step
      if(yside>zangles) yside=zangles-(yside%zangles)
    end
    -- copy to spr
    -- skip top+top rotation
    local frame,sprites=entity.frames[(yangles+1)*yside+side+1],entity.sprites
    local base,w,h=frame.base,frame.width,frame.height
    -- cache works in 10% of cases :/
    if prev_base!=base or prev_sprites!=sprites then
      prev_base,prev_sprites=base,sprites
      for i=0,(h-1)<<6,64 do
        poke4(i,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
        base+=4
      end
    end
    w0*=(thing.scale or 1)
    local sx,sy=item.x-w*w0/2,item.y-h*w0/2
    local sw,sh=w*w0+(sx&0x0.ffff),h*w0+(sy&0x0.ffff)
    --
    sspr(frame.xmin,0,w,h,sx,sy,sw,sh,flip) 
    --if(thing.radius) circ(item.x,item.y,item.key*thing.radius,9) print(thing.hp,item.x,item.y-item.key*32,8)
  end
end

-- particle thingy
function make_particle(template,_origin,_velocity)  
  local max_ttl=12+rnd"8"
  return add(_things,inherit({
    origin=_origin,
    ttl=rnd{0,1,2},
    update=function(_ENV)
      ttl+=1
      if(ttl>max_ttl) dead=true return
      -- animated?
      if(ents) ent=ents[flr(#ents*ttl/max_ttl)+1]
      -- trail
      if trail and ttl%4==0 then
        -- make sure child don't spawn other entities
        make_particle(trail,v_clone(origin),{0,0,0})
      end
      if _velocity then
        -- if moving, apply gravity
        _velocity[2]-=0.4
        origin=v_add(origin,_velocity)        
        if origin[2]<1 and _velocity[2]<0 then
          origin[2]=1 _velocity=v_scale(_velocity,0.8) _velocity[2]*=rebound
          -- write on playground
          if stain and rebound==0 then
            -- don't drop blood each time
            if rnd()>0.33 then
              -- convert coords into map space
              local sx,sy=origin[1]/3-0x6a.aaaa,origin[3]/3-0x6a.aaaa
              pset(sx,sy,stain)
            end
            dead=true
          end
        end
      end
    end
  },template))
end

function make_blood(...)
  make_particle(_gib_template,...)
end

function make_goo(...)
  return make_particle(_goo_template,...)
end

-- base class for:
-- skull I III
-- centipede
-- spiderling
-- egg
function make_skull(_ENV,_origin)
  reserve_async(cost)

  local _ENV=add(_things,inherit({},_ENV))
  origin,resolved,seed,wobble=_origin,{},lerp(seed0,seed1,rnd()),lerp(wobble0,wobble1,rnd())

  -- custom init function?
  if(init) init(_ENV)

  grid_register(_ENV)
  
  --play spawn sfx
  sfx(spawnsfx or 40)

  return _ENV
end

-- spider
function make_spider()
  local spawn_angle=rnd()
  make_skull(inherit({
    zangle=spawn_angle,
    hit=function(_ENV,pos)
      if register_hit(_ENV) then
        for i=1,8 do
          local vel=vector_in_cone(0,0,1)
          make_goo(v_add(origin,vel,rnd"8"),v_scale(vel,2+rnd"4"))
        end
        -- unregister
        dead,_spiders[_ENV]=true
        sfx"52"
      end
    end,
    update=function(_ENV)
      bright=lerp(bright,1,0.022)
      for thing in pairs(_grid[origin[1]>>21|origin[3]\32].things) do
        if thing.pickup and not thing.dead then
          local dir,len=v_dir(origin,thing.origin)
          if len<radius then
            thing:pickup(true)
            -- hp bonus when pickup up gems!
            hp+=12
            do_async(function()
              wait_async(10)
              -- spit an egg
              local angle,force=spawn_angle+rrnd"0.05",22+rnd"4"
              make_egg(v_clone(origin),{-force*cos(angle),rnd"5",force*sin(angle)})
              wait_async(20)
            end)
          end
        end
      end
      -- register for jewel attractor
      _spiders[_ENV]=origin
    end
  },_spider_template),v_clone(get_spawn_origin(220,spawn_angle),48))
end

-- squid
-- type 1: 3 blocks
-- type 2: 4 blocks
function make_squid(type)
  _spawn_angle+=lerp(0.20,0.30,rnd())
  local _spawns,_origin,_velocity,_dx,_dz,_angle,_dead=select(type,4,4,8),get_spawn_origin(256,_spawn_angle),{-cos(_spawn_angle)/16,0,sin(_spawn_angle)/16},32000,32000,0
  local function make_skull_async(template)
    make_skull(template,{_origin[1],64+rnd"16",_origin[3]})
    wait_async(2,2)
  end

  make_skull(inherit({
    init=function(_ENV)
      -- spill skulls every x seconds
      ai=do_async(function()
        wait_async(90)
        while true do
          -- don't spawn while outside
          if _dx<200 and _dz<200 then
            for i=1,_spawns do
              make_skull_async(_skull1_template)
            end
            make_skull_async(_skull2_template)
            -- wait 10s
            wait_async(300)            
          end
          yield()          
        end
      end)
      -- squid parts
      for part_template in all(_squid_templates[type]) do
        add(_things,inherit({
          hit=function(_ENV,pos,bullet) 
            if jewel then
              -- feedback
              make_particle(_lgib_template,pos,{u,-3*bullet.velocity[2],v})
              sfx"56"
              if register_hit(_ENV) then
                make_jewel(origin,{u,3,v},16)
                -- change appearance + avoid reentrancy (jewel can't be null!!)
                ent,jewel=_entities.squid2,false
                if(type==1) _dead=true music"39"
                -- "downgrade" squid!!
                type-=1
              end
            end
          end,
          update=function(_ENV)
            if _dead then
              if(dead) return
              make_blood(origin) 
              dead=true
              return
            end
            bright=lerp(bright,1,0.022)
            zangle=_angle+a_offset
            -- store u/v angle
            local cc,ss,offset=cos(zangle),-sin(zangle),r_offset
            if is_tentacle then
              yangle=-cos(time()/8+scale)*swirl
              offset+=sin(time()/4+scale)*swirl
            else
              u,v=cc,ss
              zangle+=0.5
            end
            origin=v_add(_origin,{offset*cc,y_offset,offset*ss})
            if(reg) grid_register(_ENV)
          end    
        },part_template))
      end
    end,
    think=function(_ENV)
      -- kill core
      dead=_dead

      _angle+=0.005
      -- keep "move" as the main driving force
      forces=v_add(forces,_velocity,30)
    end,
    post_think=function(_ENV)
      _origin,_dx,_dz=origin,abs(origin[1]-512),abs(origin[3]-512)
      _origin[2]=2
      -- remove squid if out of sight
      if(_dx>300 or _dz>300) _dead=true
    end
  },_squid_core),_origin)
end

-- centipede
function make_worm(type)  
  local head_template,_origin,segments,prev_angles,prev,head=_ENV["_worm_head_"..type],v_clone(get_spawn_origin(96),-64),{},{},{}  
  local templates=split(head_template.templates,"|")

  local function make_dirt(_ENV)
    for i=1,3+rnd"3" do
      make_blood(v_add(origin,{rrnd"16",1,rrnd"16"}),{0,rnd"3",0})
    end
  end

  head=make_skull(inherit({
    die=function(_ENV)
      sfx"-1"
      music"54"
      -- clean segment
      do_async(function()
        while #segments>0 do
          local _ENV=deli(segments,1)
          dead=true
          make_blood(origin,{0,0,0})
          wait_async(3)
        end
      end)
    end,
    init=function(_ENV)
      -- create segments
      for id in all(templates) do
        add(segments,add(_things,inherit({
          hit=function(_ENV,pos,bullet)
            -- tail? (no jewels)
            if(not jewel) return
            -- avoid reentrancy
            if(touched) return
            if register_hit(_ENV) then
              make_blood(pos,v_add(bullet.velocity,head.velocity))
              make_jewel(origin,head.velocity)
              -- change sprite (no jewels)
              touched,ent=true,_entities.worm2
              sfx"56"
            end
          end},_ENV["_worm_seg_"..type..id])))
      end

      ai=do_async(function()
        target=v_clone(_origin,96)
        wait_async(60)
        local w=wobble
        -- ensure centipede doesn't go underground!
        ground_limit=16
        for i=1,6 do
          target=v_rnd(512,16+rnd"48",512,96+rnd"16",atan2(origin[1],origin[3])+rnd"0.05")
          wait_async(60,10)
          wobble,target=4,v_clone(_plyr.eye_pos)          
          wait_async(180)
          wobble=w
        end
    
        target=v_clone(_plyr.eye_pos,128)
        wait_async(90)
        -- go away
        ground_limit,target=-64,v_clone(_plyr.eye_pos,-96)
        wait_async(90)
        -- wait until all segments are underground
        while true do
          for _ENV in all(segments) do
            if origin[2]>0 then
              goto above_ground
            end
            dead=true
          end
          break
    ::above_ground::
          yield()
        end
        dead=true
      end)
    end,
    think=function(_ENV)
      -- call parent
      _skull_core.think(_ENV)
      -- record last y
      prev_y=origin[2]
    end,
    post_think=function(_ENV)
      local curr_y,dirt=origin[2]
      if sgn(curr_y)!=sgn(prev_y) then
        sfx"59"
        make_dirt(_ENV)
        dirt=true
      end
      prev_y=curr_y
      add(prev,{v_clone(origin),zangle,yangle,dirt},1)
      if(#prev>#templates*4) deli(prev)
      for i=3,#prev,4 do
        local _ENV,dirt=segments[i\4+1]
        -- can happen when centipede is dying
        if _ENV then
          origin,zangle,yangle,dirt=unpack(prev[i])
          grid_register(_ENV)
          if(dirt) make_dirt(_ENV)
        end
      end
    end
  },head_template),_origin)
end

function make_jewel(_origin,_velocity)
  add(_things,inherit({    
    origin=v_clone(_origin),
    velocity=v_clone(_velocity),
    pickup=function(_ENV,spider)
      if(dead) return
      dead=true
      -- no feedback when gobbed by spider
      if(spider) return
      _G._total_jewels+=1 
      sfx"57"      
    end,
    update=function(_ENV)
      ttl-=1
      -- visible from distance
      bright=1+abs(cos(time()/2))
      -- blink when going to disapear
      if ttl<30 then
        no_render=ttl%2==0
      end
      if ttl<0 then
        dead=true
        return
      end
      -- friction
      if on_ground then
        velocity[1]*=0.95
        velocity[3]*=0.95
      end
      -- gravity
      velocity[2]-=0.8

      -- pulled by player or spiders?
      local force,min_dist,min_other=_plyr.attract_power,32000,_plyr
      for other,other_origin in pairs(_spiders) do
        local dist_dir,dist=v_dir(origin,other_origin)
        if(dist<min_dist) force,min_dist,min_other=0.05,dist,other
      end
      -- anyone stil alive?
      if not min_other.dead and force!=0 then
        -- boost repulsive force
        if(force<0) force*=2
        local new_origin=v_lerp(origin,min_other.origin,force/3)
        velocity=v_add(new_origin,origin,-1)        
        origin=new_origin
      else
        origin=v_add(origin,velocity) 
      end
      on_ground=origin[2]<8
      -- on ground?
      if on_ground then
        origin[2],velocity[2]=8,0
      end
      grid_register(_ENV)
    end
  },_jewel_template))
end

function make_egg(_origin,_velocity)
  -- spider spawn time
  local ttl,egg=300+rnd"10"
  egg=make_skull(inherit({
    think=function(_ENV)
      -- gravity
      _velocity[2]-=0.8
      forces=v_add(forces,_velocity,8)
      _velocity[1]=0
      _velocity[3]=0
    end,
    post_think=function(_ENV)
      if(hatching) return
      ttl-=1
      if ttl<0 then
        hatching=true
        -- spiderling
        ai=do_async(function()
          make_skull(inherit({
            init=function()
              -- kill egg
              local _ENV=egg
              sfx"51"
              dead=true
              for i=1,2+rnd"2" do
                local a=rnd()
                make_goo(origin,{cos(a),rnd"5",sin(a)})
              end
            end,
            think=function(_ENV)
              -- navigate to target (direct)
              local dir=v_dir(origin,_plyr.origin)
              forces=v_add(forces,dir,8)
              -- ensure spiderlings don't walk on air!
              local avoid,avoid_dist=v_dir(origin,{512,0,512})
              if avoid_dist>96 then
                forces=v_add(forces,avoid,avoid_dist*0.0833)
              end
              origin[2]=ground_limit
            end
          },_spiderling_template),origin)
        end)
      end
    end
  },_egg_template),_origin)
end

-- static "mine"
function make_mine()
  make_skull(inherit({
    origin=v_clone(_plyr.origin,128),
    update=function(_ENV)
      origin[2]=lerp(origin[2],12,0.01)
      -- no need to re-register (same y)
    end
  },_mine_template),_src)
end

-- draw game world
local _hand_y=0
function draw_world()
  cls()

  -- draw mini bsp
  _bsp[0](_cam)

  -- tilt!
  -- screen = gfx
  -- reset palette
  
  local yshift=sin(_cam.tilt)>>3
  memcpy(0xa380,0x6000,0x2000)
  for i=0,63,4 do
    -- 0xbc80 = 0x6000-0xa380
    -- offset = dst -  src
    local off=((((i-31.5)*yshift+0.5)\1)<<6)+0xbc80
    -- copy from y=4 to y=123 
    for src=0xa480+i,0xc240+i,64 do
      poke4(src+off,$src)
    end
  end

  -- hide trick top/bottom 8 pixel rows :)
  -- draw player hand (unless player is dead)
  _hand_y=lerp(_hand_y,_plyr.dead and 127 or abs(_plyr.xz_vel*cos(time()/2)*4),0.2)
  -- using poke to avoid true/false for palt
  if _plyr.fire_ttl==0 then
    exec(scanf([[memset;0x6000;0;512
memset;0x7e00;0;512
pal
pal;15;$
poke;0x5f0a;0x1a
poke;0x5f00;0x00
clip;0;8;128;112
camera;0;$
sspr;72;32;64;64;72;72
pal
clip
camera]],@(_hand_pal+(time()\0.1)%9),-_hand_y))    
  else          
    local r=24+rnd"8"
    exec(scanf([[memset;0x6000;0;512
memset;0x7e00;0;512
pal
poke;0x5f0f;0x1f
poke;0x5f00;0x00
clip;0;8;128;112
camera;0;$
poke;0x5f00;0x10
fillp;0xa5a5.8
circfill;96;96;$;8
fillp
circfill;96;96;$;7
circ;96;96;$;9
poke;0x5f00;0x0
sspr;0;64;64;64;72;64
clip
camera]],-_hand_y,r,0.9*r,0.9*r))
  end
end

-- gameplay state
function play_state()
  -- clean up stains!
  -- force GC
  exec[[_map_display;1
memcpy;0;0xc500;4096
memcpy;4096;0xc500;4096
_map_display;0
set;_total_jewels;0
set;_total_bullets;0
set;_total_hits;0
stat;0]]

  -- camera & player & reset misc values
  _plyr,_things,_spiders,_spawn_angle=make_player({512,24,512},0),{},{},rnd()
  
  -- spatial partitioning grid
  _grid=setmetatable({},{
      __index=function(self,k)
        -- automatic creation of buckets
        -- + array to store things at cell
        local t={
          things={},
          chatter=setmetatable({},{       
            __index=function(self,k)
              self[k]=0
              return 0
            end
          })
        }
        self[k]=t
        return t
      end
    })    

  return
    -- update
    function()
      _total_time+=_time_inc
      _plyr:control()
      
      _cam:track(_plyr.eye_pos,_plyr.m,_plyr.tilt)
    end,
    -- draw
    function()
      draw_world()   

      --print(((stat(1)*1000)\10).."%\n"..flr(stat(0)).."KB",2,2,3)
      --local s=_total_things.."/60 ⧗+"..tostr(_time_inc,2)
      --print(s,64-print(s,0,128)/2,2,7)

      if _show_timer then
        local t,c,prefix=tostr(_total_time*3,2),2,""
        if(_time_inc==0) c,prefix=0,"⧗ "
        t=prefix..sub(t,1,#t-2).."."..sub(t,-2).."S"        
        arizona_print(t,64-print(t,0,128)/2,1,c)
      end

      -- hw palette
      memcpy(0x5f10,_hw_pal,16)
    end,
    -- init
    function()
      exec[[sfx;-1
music;32
set;_hw_pal;0x8000]]
      -- must be done *outside* async update loop!!!
      _futures,_total_things,_total_time,_time_inc={},0,0,0x0.0001
      -- scenario
      local scenario=do_async(function()
        exec(_scenario)
        -- wait for all things to die
        while _total_things>0 do
          _time_inc=0
          yield()
        end
        exec[[wait_async;90
set;dead;1;_plyr
next_state;gameover_state;lIBERATED;256;0.01;61]]
      end)

    -- progression
    do_async(function()
      exec[[set;_fire_ttl;3
set;_shotgun_count;10
set;_shotgun_spread;0.025
set;_hand_pal;0xd500
set;_piercing;0
//;level 1
wait_jewels;10
set;_shotgun_count;20
set;_shotgun_spread;0.030
sfx;-1
music;44
levelup_async;3
//;level 2
wait_jewels;70
set;_fire_ttl;2
set;_shotgun_count;25
set;_shotgun_spread;0.033
set;_hand_pal;0xd509
set;_piercing;1
sfx;-1
music;44
levelup_async;5
//;level 3
wait_jewels;150
set;_shotgun_count;30
set;_shotgun_spread;0.037
set;_hand_pal;0xd512
set;_piercing;2
sfx;-1
music;44
levelup_async;7
wait_jewels;0x7fff]]
    end)

    do_async(function()
      -- skull 1+2 circle around player
      while not _plyr.dead do      
        local x,y,z=unpack(_plyr.origin)
        _skull_base_template.target=v_rnd(x,y+10+rnd"4",z,24*cos(time()/8))
        wait_async(10,5)
      end

      -- stop creating monsters
      scenario.co=nil

      -- if player dead, find a random spot on map
      while true do
        _skull_base_template.target=v_rnd(512,12+rnd"64",512,64)
        wait_async(60,15)
      end
    end)
  end
end

function gameover_state(obituary,height,height_attract,music_id)  
  -- remove time spent "waiting"!!
  local hw_pal,play_time,origin,target,selected_tab,clicked=0,_total_time,_plyr.eye_pos,v_add(_plyr.origin,{0,height or 4,0})
  -- check if new playtime enters leaderboard?
  -- + handle sorting
  local new_best_i=#_local_scores+1
  for i,local_score in inext,_local_scores do
    if play_time>local_score[1] then
      new_best_i=i
      break
    end
  end
  -- record time of play
  add(_local_scores,{play_time,stat(90),stat(91),stat(92)},new_best_i)
  -- max #scores
  if(#_local_scores>5) deli(_local_scores)
  -- save version
  -- death music
  -- time format v2
  exec[[sfx;-1
dset;0;2]]
  music(music_id or 36)

  -- number of scores
  dset(1,#_local_scores)
  local mem=0x5e08
  for local_score in all(_local_scores) do
    -- save
    poke4(mem,unpack(local_score))
    -- next 4 * 4bytes
    mem+=16
  end

  -- leaderboard/retry
  local ttl,buttons,over_btn=90,{
    {"rETRY",1,111,cb=function() 
      do_async(function()
        for i=0,11 do
          hw_pal=i<<4
          yield()
        end
        next_state(play_state)
      end)
    end},
    {"sTATS",1,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        local x=1
        split2d(scanf(_localboard,(play_time<<16)/30,obituary,_total_jewels,tostr(_total_bullets,2),flr(_total_bullets==0 and 0 or 1000*(_total_hits/_total_bullets))/10),
        function(s,_,y,sel)
          -- new line?
          if(_=="_") x=1
          x=arizona_print(s,x,y,sel)
        end)
      end
    },
    {"lOCAL",46,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        for i,local_score in ipairs(_local_scores) do
          local t,y,m,d=unpack(local_score)
          arizona_print(scanf("$.\t$/$/$\t $S",i,y,m,d,(t<<16)/30),1,23+i*7,new_best_i==i and 4)
        end
      end},
    {"oNLINE",96,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        arizona_print("tO BE ANNOUNCED...",1,30)
      end
    }
  }
  -- default (stats)
  selected_tab=buttons[2]
  -- get actual size
  for _,btn in pairs(buttons) do
    btn.width=print(btn[1],0,130)
  end
  -- position cursor on retry
  local _,x,y=unpack(buttons[1])
  local mx,my=x+buttons[1].width/2,y+3
  return
    -- update
    function()
      ttl=max(ttl-1)
      origin=v_lerp(origin,target,height_attract or 0.2)
      _cam:track(origin,_plyr.m,_plyr.tilt)
      if ttl==0 then
        mx,my=mid(mx+stat(38)/2,0,127),mid(my+stat(39)/2,0,127)
        -- over button?
        over_btn=-1
        for i,btn in pairs(buttons) do
          local _,x,y=unpack(btn)          
          if mx>=x and my>=y and mx<=x+btn.width and my<=y+6 then            
            over_btn=i
            -- click?
            if not clicked and btnp(5) then
              -- avoid reentrancy
              clicked=true
              btn:cb()
            end
            break
          end
        end
      end
    end,
    -- draw
    function()
      draw_world()
      if ttl==0 then
        exec[[palt;0;false
poke;0x5f54;0x00
memcpy;0x5f00;0x8200;16
sspr;0;24;128;84;0;24
poke;0x5f54;0x60
memcpy;0x5f00;0x8270;16
poke;0x5f00;0x10
arizona_print;hIGHSCORES;1;8
line;1;24;126;24;4
line;1;25;126;25;2
line;1;109;126;109;2
line;1;108;126;108;4]]
        -- darken game screen
        -- shift palette
        -- copy in place
        -- reset

        -- draw menu & all
        
        for i,btn in pairs(buttons) do
          local s,x,y=unpack(btn)
          arizona_print(s,x,y,selected_tab==btn and 2 or i==over_btn and 1)
        end

        selected_tab:draw()

        -- mouse cursor
        spr(20,mx,my)
      end
      -- hw palette
      memcpy(0x5f10,0x8000+hw_pal,16)
      -- pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- pico8 entry points
function _init()
  -- enable custom font
  -- enable tile 0 + extended memory
  -- capture mouse
  -- enable lock
  -- increase tline precision
  -- cartdata
  -- use "screen" as spritesheet source
  -- copy tiles to spritesheet 1
  -- todo: put back tline precision
  exec[[poke;0x5f58;0x81
poke;0x5f36;9
poke;0x5f2d;0x7
poke;0x5f54;0x60;0x00
memcpy;0x0;0x6000;0x2000
_map_display;1
memcpy;0;0xc500;4096
memcpy;4096;0xc500;4096
_map_display;0
cls
cartdata;freds72_daggers
tline;17]]

  -- local score version
  _local_scores,_local_best_t={}
  if dget(0)==2 then
    -- number of scores    
    local mem=0x5e08
    for i=1,dget(1) do
      -- duration (sec)
      -- timestamp yyyy,mm,dd
      add(_local_scores,{peek4(mem,4)})
      mem+=16
    end    
    _local_best_t=_local_scores[1][1]
  end

  menuitem(2,"timer on/off",function()
    _show_timer=not _show_timer
  end)

  -- always needed  
  _cam=inherit{
    origin=split"0,0,0",    
    track=function(_ENV,_origin,_m,_tilt)
      --
      tilt=_tilt or 0
      m={unpack(_m)}		

      -- inverse view matrix
      m[2],m[5]= m[5], m[2]
      m[3],m[9]= m[9], m[3]
      m[7],m[10]=m[10],m[7]
      
      origin=_origin
    end}
    
    -- mini bsp:
    --              0
    --             / \
    --           -1   grid
    --           / \
    --       brush  -2
    --             /   \ 
    --          brush  brush
    split2d([[0;2;0;-1;grid
-1;1;384.0;1;-2
-2;1;640.0;2;3]],function(id,plane_id,plane,left,right)
      _bsp[id]=function(cam)
        local l,r=_bsp[left],_bsp[right]                
        if(cam.origin[plane_id]<=plane) l,r=r,l
        l(cam)
        r(cam)
      end
    end)
    -- layout:
    -- #1: brush id (bsp node id)
    -- repeat:
    -- ##0: cp coord (!!signed!!)
    -- ##1: cp value (!!signed!!)
    -- ##2: u index
    -- ##3: v index
    -- ##4: vertex index
    -- ##5: vertex index
    -- ##6: vertex index
    -- ##7: vertex index
    -- ##8: tex coords
    split2d([[1; 2;0.0;0;2;13;16;19;22;0x0000.1010;1; -2;32.0;0;2;58;55;52;49;0x0014.0404;0; -3;-384.0;0;1;13;22;58;49;0x0010.0404;0; 3;640.0;0;1;19;16;52;55;0x0010.0404;0; -1;-320.0;2;1;49;52;16;13;0x0010.0404;0
2; 2;0.0;0;2;1;4;7;10;0x0000.1010;1; -2;32.0;0;2;46;43;40;37;0x0014.0404;0; -3;-320.0;0;1;1;10;46;37;0x0010.0404;0; 3;704.0;0;1;7;4;40;43;0x0010.0404;0; -1;-384.0;2;1;22;1;37;58;0x0010.0404;0; -1;-384.0;2;1;4;19;55;40;0x0010.0404;0; 1;640.0;2;1;28;7;43;64;0x0010.0404;0; 1;640.0;2;1;10;25;61;46;0x0010.0404;0
3; 2;0.0;0;2;25;28;31;34;0x0000.1010;1; -2;32.0;0;2;70;67;64;61;0x0014.0404;0; -3;-384.0;0;1;25;34;70;61;0x0010.0404;0; 1;704.0;2;1;70;34;31;67;0x0010.0404;0; 3;640.0;0;1;31;28;64;67;0x0010.0404;0
]],function(id,...)
      -- localize
      local planes={...}
      _bsp[id]=function(cam)        
        local m,origin,cx,cy,cz=cam.m,cam.origin,unpack(cam.origin)
        local m1,m5,m9,m2,m6,m10,m3,m7,m11=m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
        -- all brush planes
        for i=1,#planes,10 do
          -- visible?
          local dir=planes[i]
          if sgn(dir)*origin[abs(dir)]>planes[i+1] then              
            local verts,uindex,vindex,outcode,nearclip={},planes[i+2],planes[i+3],0xffff,0  
            for j=1,4 do
              local vi=planes[i+j+3]
              local code,x,y,z=2,_vertices[vi]-cx,_vertices[vi+1]-cy,_vertices[vi+2]-cz
              local ax,ay,az=m1*x+m5*y+m9*z,m2*x+m6*y+m10*z,m3*x+m7*y+m11*z
              if(az>4) code=0
              if(az>192) code|=1
              if(-0.5*ax>az) code|=4
              if(0.5*ax>az) code|=8
              
              local w=32/az 
              verts[j]={ax,ay,az,u=(_vertices[vi+uindex]-320)*0x0.aaaa,v=(_vertices[vi+vindex]-320)*0x0.aaaa,x=63.5+ax*w,y=63.5-ay*w,w=w}
              
              outcode&=code
              nearclip+=code&2
            end
            -- out of screen?
            if outcode==0 then
              if nearclip!=0 then                
                -- near clipping required?
                local res,v0={},verts[#verts]
                local d0=v0[3]-1
                for i,v1 in inext,verts do
                  local side=d0>0
                  if(side) res[#res+1]=v0
                  local d1=v1[3]-1
                  if (d1>0)!=side then
                    -- clip!
                    local t=d0/(d0-d1)
                    local v=v_lerp(v0,v1,t)
                    -- project
                    -- z is clipped to near plane
                    v.x=63.5+(v[1]<<5)
                    v.y=63.5-(v[2]<<5)
                    v.w=32 -- 32/1
                    v.u=lerp(v0.u,v1.u,t)
                    v.v=lerp(v0.v,v1.v,t)
                    res[#res+1]=v
                  end
                  v0,d0=v1,d1
                end
                verts=res
              end
    
              -- texture
              poke4(0x5f38,planes[i+8])
              _map_display(planes[i+9])
              mode7(verts,#verts,_ramp_pal+0x1100)  
            end
          end
        end
        _map_display(0)
      end
    end)
  -- attach world draw as a named BSP node
  _bsp.grid=draw_grid
  
  -- load images
  _entities=decompress("freds72_daggers_pic",0,0,unpack_entities)
  reload()

  -- must be globals
  -- predefined entries (avoids constant gc)
  _spark_trail,_blood_trail={
    _entities.spark0,
    _entities.spark1,
    _entities.spark2
  },{
    _entities.blood1,
    _entities.blood2
  }

  _skull_core=inherit({
    hit=function(_ENV,pos,bullet)
      if register_hit(_ENV) then
        dead=true
        -- custom death function?
        if die then
          die(_ENV)
        else
          sfx(death_sfx or 52)
        end
        -- drop jewel?
        if jewel then
          make_jewel(origin,velocity)
        end 
        for i=1,3+rnd"2" do
          local vel=vector_in_cone(0.25-bullet.zangle,0,0.2)
          vel[2]=rnd()
          -- custom explosion?
          make_particle(rnd()<gibs and gib or lgib,origin,v_scale(vel,1+rnd"2"))
        end
        local vel=vector_in_cone(0.25-bullet.zangle,0,0.01)
        make_particle(lgib,pos,v_scale(vel,-0.5))
      end
    end,
    apply=function(_ENV,other,force,t)
      if not apply_filter or other[apply_filter] then
        forces[1]+=t*force[1]
        forces[2]+=t*force[2]
        forces[3]+=t*force[3]
      end
      resolved[other]=true
    end,
    -- default think
    think=function(_ENV)
      -- converge toward player
      if target then
        -- add some lag to the tracking
        active_target=v_lerp(active_target or target,target,0.2+seed/16)
        local dir=v_dir(origin,active_target)
        forces=v_add(forces,dir,seed)
        forces[2]+=wobble*cos(time()/seed-seed)-wobble/8
      end
      -- move head up/down
      yangle=lerp(yangle,-mid(velocity[2]/seed/2,-0.24,0.24),0.1)
    end,
    update=function(_ENV)
      -- some friction
      velocity=v_scale(velocity,0.8)

      -- custom think function
      think(_ENV)

      -- makes the boids behavior a lot more "natural" + saves cpu
      if rnd()>0.25 then
        -- avoid others (noted: limited to a single grid cell)
        -- 21 = (x\32)>>16
        local idx,fx,fy,fz=origin[1]>>21|origin[3]\32,unpack(forces)
        for other in pairs(_grid[idx].things) do
          -- apply inverse force to other (and keep track)
          if not resolved[other] and other!=_ENV then
            local other_radius,avoid,avoid_dist=other.radius,v_dir(origin,other.origin)
            local r=(radius+other_radius)<<1
            if avoid_dist<r then
              local t=-64/(1+avoid_dist)
              local t_self=t*other_radius/radius
              fx+=t_self*avoid[1]
              fy+=t_self*avoid[2]
              fz+=t_self*avoid[3]
              
              other:apply(_ENV,avoid,-t*radius/other_radius)
            end
            resolved[other]=true
          end
        end
        forces={fx,fy,fz}

        -- 
        velocity=v_add(velocity,forces,1/16)      
      end

      -- fixed velocity (on x/z)
      if min_velocity>0 then
        local vx,vz=velocity[1],velocity[3]
        local a=atan2(vx,vz)
        local vlen=vx*cos(a)+vz*sin(a)
        velocity[1]*=min_velocity/vlen
        velocity[3]*=min_velocity/vlen      
      end

      -- align direction and sprite direction
      local target_angle=atan2(-velocity[1],velocity[3])
      zangle=lerp(shortest_angle(target_angle,zangle),target_angle,0.2)
      
      -- move & clamp
      origin[1]=mid(origin[1]+velocity[1],0,1024)
      origin[2]=max(ground_limit,origin[2]+velocity[2])
      origin[3]=mid(origin[3]+velocity[3],0,1024)

      -- for centipede
      if(post_think) post_think(_ENV)

      -- reset
      forces,resolved={0,0,0},{}
      grid_register(_ENV)
    end
  })

  -- global templates
  split2d([[_gib_trail;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,ent,blood1,@ents,_blood_trail,rebound,0,stain,5
_gib_template;radius,4,zangle,0,yangle,0,ttl,0,scale,1,@trail,_gib_trail,ent,blood0,rebound,0.8
_lgib_template;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,@trail,_gib_trail,ent,blood1,rebound,-1
_goo_trail;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,ent,goo0,rebound,0,stain,7
_goo_template;radius,4,zangle,0,yangle,0,ttl,0,scale,1,@trail,_goo_trail,ent,goo0,rebound,-1
_dagger_hit_template;shadeless,1,zangle,0,yangle,0,ttl,0,scale,1,ent,spark0,@ents,_spark_trail,rebound,1.2
_skull_template;reg,1,wobble0,2,wobble1,3,seed0,6,seed1,7,zangle,0,yangle,0,hit_ttl,0,forces,v_zero,velocity,v_zero,min_velocity,3,ground_limit,8,target_yangle,-0.1,gibs,-1,@gib,_gib_template,@lgib,_lgib_template,cost,1;_skull_core
_egg_template;ent,egg,radius,8,hp,2,zangle,0,@apply,nop,obituary,aCIDIFIED,min_velocity,-1,@lgib,_goo_template;_skull_template
_worm_seg_normal0;hit_ttl,0,reg,1,ent,worm1,s_radius,9,radius,12,zangle,0,origin,v_zero,@apply,nop,obituary,sLICED,scale,1.5,jewel,1,hp,5
_worm_seg_mega0;hit_ttl,0,reg,1,ent,worm1,s_radius,10,radius,16,zangle,0,origin,v_zero,@apply,nop,obituary,mINCED,scale,1.7,jewel,1,hp,10
_worm_seg_giga0;hit_ttl,0,reg,1,ent,worm1,s_radius,11,radius,20,zangle,0,origin,v_zero,@apply,nop,obituary,gUTTED,scale,1.9,jewel,1,hp,30
_worm_seg_tail1;reg,1,ent,worm2,radius,8,zangle,0,origin,v_zero,@apply,nop,obituary,pIERCED,scale,1.2,s_radius,7
_worm_seg_tail2;reg,1,ent,worm2,radius,8,zangle,0,origin,v_zero,@apply,nop,obituary,pIERCED,scale,0.8,s_radius,4
_worm_seg_normal1;;_worm_seg_tail1
_worm_seg_mega1;;_worm_seg_tail1
_worm_seg_giga1;;_worm_seg_tail1
_worm_seg_normal2;;_worm_seg_tail2
_worm_seg_mega2;;_worm_seg_tail2
_worm_seg_giga2;;_worm_seg_tail2
_worm_head_normal;hit_ttl,0,wobble0,9,wobble1,12,seed0,5,seed1,6,ent,worm0,s_radius,12,radius,16,hp,50,chatter,20,spawnsfx,42,obituary,sLICED,ground_limit,-64,cost,10,gibs,0.5,templates,0|0|0|0|0|0|0|0|0|0|1|2;_skull_template
_worm_head_mega;hit_ttl,0,wobble0,8,wobble1,11,seed0,3,seed1,4.5,ent,worm0,s_radius,14,radius,20,scale,1.2,hp,200,chatter,20,spawnsfx,42,obituary,mINCED,ground_limit,-64,cost,15,gibs,0.7,templates,0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|1|2;_skull_template
_worm_head_giga;hit_ttl,0,wobble0,7,wobble1,10,seed0,2,seed1,3.5,ent,worm0,s_radius,16,radius,22,scale,1.5,hp,400,chatter,20,spawnsfx,42,obituary,gUTTED,ground_limit,-64,cost,20,gibs,1,templates,0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|0|1|2;_skull_template
_jewel_template;reg,1,ent,jewel,s_radius,8,radius,12,zangle,0,ttl,300,@apply,nop
_spiderling_template;ent,spiderling0,radius,8,hp,2,on_ground,1,death_sfx,53,chatter,16,obituary,wEBBED,apply_filter,on_ground,@lgib,_goo_template,ground_limit,2;_skull_template
_squid_core;no_render,1,s_radius,18,radius,24,origin,v_zero,on_ground,1,is_squid_core,1,min_velocity,0.2,chatter,8,@hit,nop,cost,5,obituary,nAILED,gibs,0.8,apply_filter,is_squid_core;_skull_template
_squid_hood;bright,0,ent,squid2,radius,12,origin,v_zero,zangle,0,@apply,nop,obituary,nAILED,shadeless,1,o_offset,18,y_offset,24,r_offset,8
_squid_jewel;bright,0,hit_ttl,0,reg,1,jewel,1,hp,7,ent,squid1,radius,8,origin,v_zero,zangle,0,@apply,nop,obituary,nAILED,shadeless,1,o_offset,18,y_offset,24,r_offset,8
_squid_tentacle;bright,0,ent,tentacle0,origin,v_zero,zangle,0,is_tentacle,1,shadeless,1,r_offset,12
_skull_base_template;;_skull_template
_skull1_template;chatter,12,ent,skull,radius,8,hp,2,obituary,bUMPED,target_yangle,0.1;_skull_base_template
_skull2_template;chatter,12,ent,reaper,radius,10,hp,4,seed0,5.5,seed1,6,jewel,1,obituary,iMPALED,min_velocity,3.5,gibs,0.2;_skull_base_template
_spider_template;bright,0,ent,spider1,radius,24,shadeless,1,hp,12,spawnsfx,41,chatter,24,zangle,0,yangle,0,scale,1.5,@apply,nop;_skull_base_template
_mine_template;ent,mine,radius,12,hp,200,spawnsfx,49,death_sfx,53,obituary,pOISONED,@apply,nop,@lgib,_goo_template,gibs,0,ground_limit,12;_skull_template]],
  function(name,template,parent)
    _ENV[name]=inherit(with_properties(template),_ENV[parent])
  end)

  for i,squid_cfg in inext,{
-- type 1 (1 jewel)
[[_squid_jewel;a_offset,0.0
_squid_hood;a_offset,0.3333
_squid_hood;a_offset,0.6667
_squid_tentacle;a_offset,0.0,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.0,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.0,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.0,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2
_squid_tentacle;a_offset,0.3333,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.3333,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.3333,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.3333,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2
_squid_tentacle;a_offset,0.6667,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.6667,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.6667,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.6667,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2]],
    -- type 2 (2 jewels)
[[_squid_jewel;a_offset,0.0
_squid_hood;a_offset,0.25
_squid_jewel;a_offset,0.5
_squid_hood;a_offset,0.75
_squid_tentacle;a_offset,0.0,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.0,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.0,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.0,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2
_squid_tentacle;a_offset,0.25,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.25,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.25,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.25,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2
_squid_tentacle;a_offset,0.5,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.5,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.5,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.5,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2
_squid_tentacle;a_offset,0.75,scale,1.0,swirl,0.0,radius,8.0,y_offset,52.0
_squid_tentacle;a_offset,0.75,scale,0.8,swirl,0.6667,radius,6.4,y_offset,60.0
_squid_tentacle;a_offset,0.75,scale,0.6,swirl,1.333,radius,4.8,y_offset,66.4
_squid_tentacle;a_offset,0.75,scale,0.4,swirl,2.0,radius,3.2,y_offset,71.2]],
  -- type 3 (without tentacles)
[[_squid_jewel;a_offset,0.0,hp,21,r_offset,22
_squid_hood;a_offset,0.1667,r_offset,22
_squid_jewel;a_offset,0.3333,hp,21,r_offset,22
_squid_hood;a_offset,0.5,r_offset,22
_squid_jewel;a_offset,0.6667,hp,21,r_offset,22
_squid_hood;a_offset,0.8333,r_offset,22]]} do
    split2d(squid_cfg,function(parent,properties)
      add(_squid_templates[i],inherit(with_properties(properties),_ENV[parent]))
    end)
  end

  -- run game
  next_state(play_state)
end

-- collect all grids touched by (a,b) vector
function collect_grid(a,b,u,v,cb)
  local mapx,mapy=a[1]\32,a[3]\32
  -- check first cell (always)
  -- pack lookup index into a single 16:16 value
  local dest_idx,map_idx=b[3]\32|b[1]\32>>16,mapy|mapx>>16
  cb(_grid[map_idx].things)
  -- early exit
  if dest_idx==map_idx then    
    return
  end

  local ddx,ddy,distx,disty,mapdx,mapdy=abs(1/u),abs(1/v)
  if u<0 then
    -- -1>>16
    mapdx,distx=0xffff.ffff,(a[1]/32-mapx)*ddx
  else
    -- 1>>16
    mapdx,distx=0x0.0001,(mapx+1-a[1]/32)*ddx
  end
  
  if v<0 then
    mapdy,disty=-1,(a[3]/32-mapy)*ddy
  else
    mapdy,disty=1,(mapy+1-a[3]/32)*ddy
  end
  while dest_idx!=map_idx do
    if distx<disty then
      distx+=ddx
      map_idx+=mapdx
    else
      disty+=ddy
      map_idx+=mapdy
    end
    cb(_grid[map_idx].things)
  end
end

function _update()
  -- any futures?
  for i=#_futures,1,-1 do
    -- get actual coroutine
    local f=_futures[i].co
    -- still active?
    if f and costatus(f)=="suspended" then
      assert(coresume(f))
    else
      deli(_futures,i)
    end
  end
  
  _plyr:update()
  --
  if _slow_mo%2==0 then
    -- draw on tiles setup
    exec[[_map_display;1
poke;0x5f54;0x00;0x60
poke;0x5f5e;0b11110110]]
    -- physic must run *before* general updates
    for _,_ENV in inext,_things do
      if(physic) physic(_ENV)
    end
    for i=#_things,1,-1 do
      local _ENV=_things[i]
      if dead then
        if(cost) _total_things=max(_total_things-cost)
        if(reg) grid_unregister(_ENV)
        -- kill ai coroutine (if any)
        if(ai) ai.co=nil
        deli(_things,i)
      else
        -- common timers
        if(hit_ttl) hit_ttl=max(hit_ttl-1)
        if(update) update(_ENV)
      end
    end
    -- revert
    exec[[poke;0x5f5e;0xff
poke;0x5f54;0x60;0x00
_map_display;0]]
  end

  _update_state()
end

-- unpack assets
function unpack_entities()
  local entities,names={},with_properties"1,skull,2,reaper,3,blood0,4,blood1,5,blood2,6,dagger0,7,dagger1,12,goo0,13,goo1,14,goo2,15,egg,16,spiderling0,17,spiderling1,18,worm0,19,worm1,20,jewel,21,worm2,22,tentacle0,23,tentacle1,24,squid0,25,squid1,26,squid2,27,spider0,28,spider1,29,spark0,30,spark1,31,spark2,32,mine"
  unpack_array(function()
    local name,sprites,angles=names[mpeek()],{},mpeek()
    local data={  
      sprites=sprites,   
      yangles=angles&0xf,
      zangles=angles\16,        
      frames=unpack_frames(sprites)
    }
    -- some entries are not needed for game
    if(name) entities[name]=data
  end)
  return entities
end

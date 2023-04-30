local _plyr,_cam,_things,_grid,_futures
local _entities,_particles,_bullets
-- stats
local _total_jewels,_total_bullets,_total_hits,_start_time=0,0,0

local _ground={
  -- middle chunk
  {
    n={0,1,0},
    split"256,0,192",
    split"256,0,832",
    split"768,0,832",
    split"768,0,192"
  },
  -- left
  {
    n={0,1,0},
    split"192,0,256",
    split"192,0,768",
    split"256,0,768",
    split"256,0,256"
  },
  -- right
  {
    n={0,1,0},
    split"768,0,256",
    split"768,0,768",
    split"832,0,768",
    split"832,0,256"
  }
}
local _sides={
  {
    n={-1,0,0},
    split"256,0,256",
    split"256,0,192",
    split"256,-32,192",
    split"256,-32,256",
  },
  {
    n={1,0,0},
    split"768,0,192",
    split"768,0,256",
    split"768,-32,256",
    split"768,-32,192",
  },
  {
    n={-1,0,0},
    split"256,0,832",
    split"256,0,768",
    split"256,-32,768",
    split"256,-32,832",
  },
  {
    n={1,0,0},
    split"768,0,768",
    split"768,0,832",
    split"768,-32,832",
    split"768,-32,768",
  },
  {
    n={0,0,1},
    split"768,0,832",
    split"256,0,832",
    split"256,-32,832",
    split"768,-32,832",
  },
  {
    n={0,0,-1},
    split"256,0,192",
    split"768,0,192",
    split"768,-32,192",
    split"256,-32,192",
  },
  -- ears (left)
  {
    n={-1,0,0},
    split"192,0,768",
    split"192,0,256",
    split"192,-32,256",
    split"192,-32,768",
  },
  {
    n={0,0,1},
    split"256,0,768",
    split"192,0,768",
    split"192,-32,768",
    split"256,-32,768",
  },
  {
    n={0,0,-1},
    split"192,0,256",
    split"256,0,256",
    split"256,-32,256",
    split"192,-32,256",
  },
  -- ears (right)
  {
    n={1,0,0},
    split"832,0,256",
    split"832,0,768",
    split"832,-32,768",
    split"832,-32,256",
  },
  {
    n={0,0,1},
    split"832,0,768",
    split"768,0,768",
    split"768,-32,768",
    split"832,-32,768",
  },
  {
    n={0,0,-1},
    split"768,0,256",
    split"832,0,256",
    split"832,-32,256",
    split"768,-32,256",
  }  
}
  
local _ground_extents={
  split"256,768,192,832",
  split"192,256,256,768",
  split"768,832,256,768"
}

function make_fps_cam()
    return {
        origin={0,0,0},    
        track=function(self,origin,m,angles,tilt)
            self.tilt=tilt or 0
            local m={unpack(m)}		

            -- inverse view matrix
            m[2],m[5]=m[5],m[2]
            m[3],m[9]=m[9],m[3]
            m[7],m[10]=m[10],m[7]

            -- todo: remove mxm code!
            self.m=m_x_m(m,{
                1,0,0,0,
                0,1,0,0,
                0,0,1,0,
                -origin[1],-origin[2],-origin[3],1
            })
            self.origin=origin
        end
    }
end

function make_player(origin,a)
    local angle,dangle,velocity,on_ground,dead={0,a,0},{0,0,0},{0,0,0,}
    local fire_ttl,fire_released,fire_frames,dblclick_ttl,fire=0,true,0,0
    return {
      -- start above floor
      origin=v_add(origin,{0,1,0}), 
      eye_pos=v_add(origin,{0,24,0}),
      tilt=0, 
      attract_power=0,  
      m=make_m_from_euler(unpack(angle)),
      control=function(self)
        if(dead) return
        -- move
        local dx,dz,a,jmp=0,0,angle[2],0
        if(btn(0,1)) dx=3
        if(btn(1,1)) dx=-3
        if(btn(2,1)) dz=3
        if(btn(3,1)) dz=-3
        if(on_ground and btnp(4)) jmp=12 on_ground=false

        -- straffing = faster!

        -- restore attrack power
        self.attract_power=min(self.attract_power+0.2,1)

        -- double-click detector
        dblclick_ttl=max(dblclick_ttl-1)
        if btn(5) then
          if fire_released then
            fire_released=false
          end
          fire_frames+=1
          -- regular fire      
          if dblclick_ttl==0 and fire_ttl<=0 then
            sfx(48)
            fire_ttl,fire=3,1
          end
          -- 
          self.attract_power=0
        elseif not fire_released then
          if dblclick_ttl>0  then
            -- double click timer still active?
            fire_ttl,fire=0,2
            dblclick_ttl=0				
            sfx(49)
            -- shotgun (repulsive!)
            self.attract_power=-1
          elseif fire_frames<4 then
           -- candidate for double click?
           dblclick_ttl=8
          end           
          fire_released,fire_frames=true,0
        end

        dangle=v_add(dangle,{stat(39),stat(38),0})
        self.tilt+=dx/40
        local c,s=cos(a),-sin(a)
        velocity=v_add(velocity,{s*dz-c*dx,jmp,c*dz+s*dx},0.5)                 
      end,
      update=function(self)
        -- damping      
        dangle=v_scale(dangle,0.6)
        self.tilt*=0.6
        if(abs(self.tilt)<=0.0001) self.tilt=0
        velocity[1]*=0.7
        --velocity[2]*=0.9
        velocity[3]*=0.7
        -- gravity
        velocity[2]-=0.8
        
        -- avoid overflow!
        fire_ttl=max(fire_ttl-1)

        angle=v_add(angle,dangle,1/1024)
  
        -- check next position
        local vn,vl=v_normz(velocity)      
        local new_pos,new_vel,new_ground=v_add(self.origin,velocity),velocity,self.ground
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
              else
                dying=true
              end
            end
            -- use corrected velocity + stays within grid
            self.origin={mid(x,0,1024),y,mid(z,0,1024)}
            velocity=new_vel
        end

        self.eye_pos=v_add(self.origin,{0,24,0})

        -- check collisions
        --[[
        if not dead then   
          local things=_grid[world_to_grid(self.eye_pos)]
          for thing in pairs(things) do
            if thing!=self then
              local dist=v_len(self.eye_pos,thing.origin)
              if dist<16 then
                -- avoid reentrancy
                dead=true
                next_state(gameover_state,thing.obituary)
                break
              end
            end
          end
        end
        ]]

        self.m=make_m_from_euler(unpack(angle))   
        self.angle=angle         

        -- normal fire
        if fire==1 then          
          _total_bullets+=0x0.0001
          make_bullet(v_add(self.origin,{0,18,0}),angle[2],angle[1],0.02)
        elseif fire==2 then
          -- shotgun
          _total_bullets+=0x0.000a
          local o=v_add(self.origin,{0,18,0})
          for i=1,10 do
            make_bullet(o,angle[2],angle[1],0.025)
          end
        end
        fire=nil          
      end
    } 
end

function make_bullet(origin,zangle,yangle,spread)
  local zangle,yscale=0.25-zangle+(1-rnd(2))*spread,yangle+(1-rnd(2))*spread
  local u,v,r=cos(zangle),-sin(zangle),cos(yscale)
  -- local o=v_add(origin,v_add(v_scale(m_up(m),1-rnd(2)),m_right(m),1-rnd(2)))
  _bullets[#_bullets+1]={
    origin=v_clone(origin),
    velocity={r*u,sin(yscale),r*v},
    -- fixed zangle
    zangle=zangle,
    yangle=rnd(),
    -- precomputed for collision detection
    u=u,
    v=v,
    ttl=time()+3+rnd(2),
    ent=rnd{_entities.dagger0,_entities.dagger1}
  }
end

function make_particle(origin,fwd)
  _particles[#_particles+1]={
    origin=origin,
    velocity=fwd,
    ttl=time()+0.25+rnd()/5,
    c=15
  }
end

-- transform & clip polygon
function draw_poly(poly,uindex,vindex,light)
    if(v_dot(_cam.origin,poly.n)<=poly.cp) return

    local m=_cam.m
    local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]
    local verts,outcode,nearclip={},0xffff,0  
    -- to cam space + clipping flags
    for i,v0 in ipairs(poly) do
        local code,x,y,z=2,v0[1],v0[2],v0[3]
        local ax,ay,az=m1*x+m5*y+m9*z+m13,m2*x+m6*y+m10*z+m14,m3*x+m7*y+m11*z+m15
        if(az>8) code=0
        if(az>384) code|=1
        if(-ax>az) code|=4
        if(ax>az) code|=8
        
        local w=64/az 
        verts[i]={ax,ay,az,u=v0[uindex]>>4,v=v0[vindex]>>4,x=63.5+ax*w,y=63.5-ay*w,w=w}

        outcode&=code
        nearclip+=code&2
    end
    -- out of screen?
    if outcode==0 then
      if nearclip!=0 then
        -- near clipping required?
        local res,v0={},verts[#verts]
        local d0=v0[3]-8
        for i,v1 in inext,verts do
          local side=d0>0
          if(side) res[#res+1]=v0
          local d1=v1[3]-8
          if (d1>0)!=side then
            -- clip!
            local t=d0/(d0-d1)
            local v=v_lerp(v0,v1,t)
            -- project
            -- z is clipped to near plane
            v.x=63.5+(v[1]<<3)
            v.y=63.5-(v[2]<<3)
            v.w=64/8
            v.u=lerp(v0.u,v1.u,t)
            v.v=lerp(v0.v,v1.v,t)
            res[#res+1]=v
          end
          v0,d0=v1,d1
        end
        verts=res
      end
      mode7(verts,#verts,light)
    end    
end

function mode7(p,np,light)
  local miny,maxy,mini=32000,-32000
  -- find extent
  for i=1,np do
    local y=p[i].y
    if (y<miny) mini,miny=i,y
    if (y>maxy) maxy=y
  end

  --data for left & right edges:
  local lj,rj,ly,ry,lx,ldx,rx,rdx,lu,ldu,lv,ldv,ru,rdu,rv,rdv,lw,ldw,rw,rdw=mini,mini,miny-1,miny-1
  local maxlight,pal0=light\0.066666
  --step through scanlines.
  if(maxy>127) maxy=127
  if(miny<0) miny=-1
  for y=1+miny&-1,maxy do
    --maybe update to next vert
    while ly<y do
      local v0=p[lj]
      lj+=1
      if (lj>np) lj=1
      local v1=p[lj]
      -- make sure w gets enough precision
      local y0,y1,w1=v0.y,v1.y,v1.w
      local dy=y1-y0
      ly=y1&-1
      lx=v0.x
      lw=v0.w
      lu=v0.u*lw
      lv=v0.v*lw
      ldx=(v1.x-lx)/dy
      ldu=(v1.u*w1-lu)/dy
      ldv=(v1.v*w1-lv)/dy
      ldw=(w1-lw)/dy
      --sub-pixel correction
      local dy=y-y0
      lx+=dy*ldx
      lu+=dy*ldu
      lv+=dy*ldv
      lw+=dy*ldw
    end   
    while ry<y do
      local v0=p[rj]
      rj-=1
      if (rj<1) rj=np
      local v1=p[rj]
      local y0,y1,w1=v0.y,v1.y,v1.w
      local dy=y1-y0
      ry=y1&-1
      rx=v0.x
      rw=v0.w
      ru=v0.u*rw
      rv=v0.v*rw
      rdx=(v1.x-rx)/dy
      rdu=(v1.u*w1-ru)/dy
      rdv=(v1.v*w1-rv)/dy
      rdw=(w1-rw)/dy
      --sub-pixel correction
      local dy=y-y0
      rx+=dy*rdx
      ru+=dy*rdu
      rv+=dy*rdv
      rw+=dy*rdw
    end
    
    -- rectfill(rx,y,lx,y,8/rw)
    if rw>0.15 then
        --[[
        -- light circle
        local d=7+(1/rw)
        if d<64 then
        local xmax=64*sqrt(64-d*d)
        local xmin=64-xmax
        xmax=64+xmax
        --rectfill(-x+64,y,64+x,y,3)
        --]]
        local rx,lx,ru,rv,lu,lv=rx,lx,ru,rv,lu,lv
        local ddx=lx-rx--((lx+0x1.ffff)&-1)-(rx&-1)
        local ddu,ddv=(lu-ru)/ddx,(lv-rv)/ddx
        --if(rx<0) ru-=rx*ddu rv-=rx*ddv rx=0
        --if(lx>=127) lu+=(128-lx)*ddu lv+=(128-lx)*ddv lx=128
        if rx<lx then
          local pal1=rw>0.9375 and maxlight or (light*rw)\0.0625
          if(pal0!=pal1) memcpy(0x5f00,0x8000|pal1<<4,16) pal0=pal1	-- color shift now to free up a variable
          -- refresh actual extent
          -- ddx=lx-rx--((lx+0x1.ffff)&-1)-(rx&-1)
          -- ddu,ddv=(lu-ru)/ddx,(lv-rv)/ddx
          local pix=1-rx&0x0.ffff
          tline(rx,y,lx\1-1,y,(ru+pix*ddu)/rw,(rv+pix*ddv)/rw,ddu/rw,ddv/rw)
      end
    end

    lx+=ldx
    lu+=ldu
    lv+=ldv
    lw+=ldw
    rx+=rdx
    ru+=rdu
    rv+=rdv
    rw+=rdw
  end      
end

-- grid helpers
function world_to_grid(p)
  return (p[1]\32)>>16|(p[3]\32)
end

-- adds thing in the collision grid
function grid_register(thing)
  local id=world_to_grid(thing.origin)
  _grid[id][thing]=true
end

-- removes thing from the collision grid
function grid_unregister(thing)
  local id=world_to_grid(thing.origin)
  _grid[id][thing]=nil
end

function draw_grid(cam,light)
  local m,fov=cam.m,cam.fov
  local cx,cy,cz=unpack(cam.origin)
  local m1,m5,m9,m13,m2,m6,m10,m14,m3,m7,m11,m15=m[1],m[5],m[9],m[13],m[2],m[6],m[10],m[14],m[3],m[7],m[11],m[15]

  local things={}
  -- particles
  poke4(0x5f38,0x0400.0101)

  -- render shadows (& collect)
  poke(0x5f5e, 0b11111110)
  color(1)
  for _,thing in pairs(_things) do
    local origin=thing.origin
    local x,z=origin[1],origin[3]
    -- draw shadows (y=0)
    local ax,az=m1*x+m9*z+m13,m3*x+m11*z+m15
    if not thing.shadeless and az>8 and az<384 and ax<az and -ax<az then
      local ay=m2*x+m10*z+m14
      -- 
      local w=64/az
      -- thing offset+cam offset              
      local dx,dz=cx-x,cz-z
      local a=atan2(dx,dz)        
      local a,r=atan2(dx*cos(a)+dz*sin(a),cy),4*w
      local ry=-r*sin(a)
      local x0,y0=63.5+ax*w,63.5-ay*w
      ovalfill(x0-r,y0-ry,x0+r,y0+ry)
    end

    local x,y,z=origin[1],origin[2],origin[3]
    if thing!=_plyr then
      -- collect monsters
      local ax,az=m1*x+m5*y+m9*z+m13,m3*x+m7*y+m11*z+m15
      if az>8 and az<384 and ax<2*az and -ax<2*az then
        local ay=m2*x+m6*y+m10*z+m14
        local w=64/az
        things[#things+1]={key=w,type=1,thing=thing,x=63.5+ax*w,y=63.5-ay*w}      
      end
    end
  end
  poke(0x5f5e, 0xff)

  local function project_array(array,type)
    for i,a in pairs(array) do
      local origin=a.origin
      local x,y,z=origin[1],origin[2],origin[3]
      -- 
      local ax,az=m1*x+m5*y+m9*z+m13,m3*x+m7*y+m11*z+m15
      if az>8 and az<384 and ax<az and -ax<az then
        local ay=m2*x+m6*y+m10*z+m14
      
        local w=64/az
        things[#things+1]={key=w,type=type,thing=a,x=63.5+ax*w,y=63.5-ay*w}      
      end
    end
  end
  -- collect bullets
  project_array(_bullets,1)
  -- collect particles
  project_array(_particles,3)

  -- radix sort
  bench_start("rsort")
  rsort(things)
  bench_end()

  -- render in order
  local prev_base,prev_sprites,pal0
  for _,item in ipairs(things) do
    local hit_ttl,pal1=item.thing.hit_ttl
    if hit_ttl and hit_ttl>0 then
      pal1=16+(4-hit_ttl)
    else
      pal1=(light*min(15,item.key<<4))\1
    end    
    if(pal0!=pal1) memcpy(0x5f00,0x8000+(pal1<<4),16) palt(0,true) pal0=pal1   
    if item.type==1 then
      -- draw things
      local w0,thing=item.key,item.thing
      local entity,origin=thing.ent,thing.origin
      -- zangle (horizontal)
      local dx,dz=cx-origin[1],cz-origin[3]
      local zangle=atan2(dx,-dz)
      local side,flip=((zangle-thing.zangle+0.5+0.0625)&0x0.ffff)\0.125
      if(side>4) side=4-(side%4) flip=true
      
      -- up/down angle
      local yangle=thing.yangle or 0
      local yside=((atan2(dx*cos(-zangle)+dz*sin(-zangle),-cy+origin[2])-0.25+0.0625+yangle)&0x0.ffff)\0.125
      if(yside>4) yside=4-(yside%4)
      -- copy to spr
      -- skip top+top rotation
      local frame,sprites=entity.frames[5*yside+side+1],entity.sprites
      local mem,base,w,h=0x0,frame.base,frame.width,frame.height
      if prev_base!=base and prev_sprites!=sprites then
        for i=mem,mem+(h-1)<<6,64 do
          poke4(i,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
          base+=4
        end
        prev_base,prev_sprites=base,sprites
      end
      w0*=2
      local sx,sy=item.x-w*w0/4,item.y-h*w0/4
      --
      sspr(frame.xmin,0,w,h,sx,sy,w*w0/2+(sx&0x0.ffff),h*w0/2+(sy&0x0.ffff),flip)
      
      --sspr(0,0,32,32,sx,sy,32,32,flip)
      --print(thing.zangle,sx+sw/2,sy-8,9)      
    elseif item.type==2 then
      --tline(item.x0,item.y0,item.x1,item.y1,item.thing.c,0,0,1/8)
    elseif item.type==3 then
      local origin=item.thing.prev
      local x,y,z=origin[1],origin[2],origin[3]
      -- 
      local ax,az=m1*x+m5*y+m9*z+m13,m3*x+m7*y+m11*z+m15
      if az>8 then
        local ay,w=m2*x+m6*y+m10*z+m14,64/az
        tline(item.x,item.y,63.5+ax*w,63.5-ay*w,0,0,1/8,0)
      end
    end
  end 

  --[[
  for _,thing in pairs(_things) do
    local x,_,z=unpack(thing.origin)
    local x0,y0=128*((x-256)/512),128*((z-256)/512)
    if thing==_plyr then
      spr(7,x0,y0)
    else
      pset(x0,y0,9)
    end
  end
  ]]
end

function inherit(t,env)
  return setmetatable(t,{__index=env or _ENV})
end

-- things
-- flying things:
local _flying_target
-- skull I II III
-- spiderling
function make_skull(actor,_origin)
  local vel={0,0,0}
  local wobling=3+rnd(2)
  local resolved={}
  local thing=add(_things,
    inherit({
      origin=_origin,
      zangle=rnd(),
      yangle=0,
      hit_ttl=0,
      forces={0,0,0},
      seed=rnd(16),
      hit=function(_ENV)
        -- avoid reentrancy
        if(dead) return
        hp-=1
        if hp<=0 then
          dead=true   
          -- draw jewel?
          if jewel then
            make_jewel(origin,vel)
          end 
          grid_unregister(_ENV)  
          make_blood(origin)
        else
          hit_ttl=5
        end
      end,
      apply=function(_ENV,other,force,t)
        forces[1]+=t*force[1]
        forces[2]+=t*force[2]
        forces[3]+=t*force[3]
        resolved[other]=true
      end,
      update=function(_ENV)
        grid_unregister(_ENV)
        hit_ttl=max(hit_ttl-1)
        -- some gravity
        if not on_ground then
          if origin[2]<12 then 
            forces={0,wobling,0}
          elseif origin[2]>80 then
            forces={0,-wobling*2,0}
          end
        end
        -- some friction
        vel=v_scale(vel,0.9)

        -- custom think function
        think(_ENV)

        -- avoid others
        local idx=world_to_grid(origin)
        
        local fx,fy,fz=forces[1],forces[2],forces[3]
        for other in pairs(_grid[idx]) do
          -- todo: apply inverse force to other (and keep track)
          if not resolved[other] then
            local avoid,avoid_dist=v_dir(origin,other.origin)
            if(avoid_dist<1) avoid_dist=1
            local t=-12/avoid_dist
            fx+=t*avoid[1]
            fy+=t*avoid[2]
            fz+=t*avoid[3]

            other:apply(_ENV,avoid,-t)
            resolved[other]=true
          end
        end
        forces={fx,fy,fz}

        local old_vel=vel
        vel=v_add(vel,forces,1/30)
        -- fixed velocity (on x/z)
        local vx,vz=vel[1],vel[3]
        local vlen=sqrt(vx*vx+vz*vz)
        vel[1]*=4/vlen
        vel[3]*=4/vlen
        
        -- align direction and sprite direction
        local target_angle=atan2(old_vel[1]-vel[1],vel[3]-old_vel[3])
        local shortest=shortest_angle(target_angle,zangle)
        --[[
        if abs(target_angle-shortest)>0.125/2 then
          -- relative change
          shortest=mid(shortest-target_angle,-0.125/2,0.125/2)
          -- preserve length
          local x,z=vel[1],vel[3]
          local len=sqrt(x*x+z*z)
          x,z=old_vel[1],old_vel[3]
          local old_len=sqrt(x*x+z*z)
          x/=old_len
          z/=old_len
          vel[1],vel[3]=len*(x*cos(shortest)+z*sin(shortest)),len*(-x*sin(shortest)+z*cos(shortest))
          shortest+=target_angle
        end
        ]]
        zangle=lerp(shortest,target_angle,0.2)
        
        -- move & clamp
        origin[1]=mid(origin[1]+vel[1],0,1024)
        origin[2]=max(4,origin[2]+vel[2])
        origin[3]=mid(origin[3]+vel[3],0,1024)

        -- for centipede
        if(post_think) post_think(_ENV)

        forces={0,0,0}
        resolved={}
        grid_register(_ENV)
      end
    },
    inherit(actor)))
  grid_register(thing)
  return thing
end

-- centipede
function make_worm(_origin)  
  local segments,prev,target_ttl={},{},0

  for i=1,20 do
    local seg=add(segments,add(_things,inherit{
      ent=_entities.worm1,
      zangle=0.25,
      origin={0,0,0},
      apply=function()
        -- do not interact with others
      end,
      hit=function(_ENV)
        -- avoid reentrancy
        if(dead) return
        make_jewel(origin,{0,0,0})
        dead=true
      end
    }))
    grid_register(seg)
  end

  make_skull({
    ent=_entities.worm0,
    hp=200,
    apply=function()
      -- 
    end,
    think=function(_ENV)
      target_ttl-=1
      if target_ttl<0 then  
        -- circle
        local a=atan2(origin[1]-512,origin[3]-512)+rnd(0.1)
        local r=96+rnd(32)
        target={512+r*cos(a),16+rnd(48),512-r*sin(a)}
        target_ttl=90+rnd(10)
      end
      -- navigate to target
      local dir=v_dir(origin,target)
      forces=v_add(forces,dir,8+seed*cos(time()/5))
    end,
    post_think=function(_ENV)
      origin[2]=40+24*sin(time()/6)
      add(prev,v_clone(origin),1)
      if(#prev>40) deli(prev)
      for i=1,#prev,2 do
        segments[i\2+1].origin=prev[i]
      end
    end
  },_origin)
end

function make_jewel(_origin,vel)
  local thing=add(_things,inherit({    
    ent=_entities.jewel,    
    origin=v_clone(_origin),
    -- random aspect
    zangle=rnd(),
    ttl=3000,
    -- 
    pickup=true,
    apply=function()
      -- do not react to others
    end,
    update=function(_ENV)
      grid_unregister(_ENV)
      ttl-=1
      if ttl<0 then
        dead=true
        return
      end
      -- friction
      if on_ground then
        vel[1]*=0.9
        vel[3]*=0.9
      end
      -- gravity
      vel[2]-=0.8

      -- pulled by player?
      if not _plyr.dead then
        local force=_plyr.attract_power
        if force!=0 then
          local a=atan2(origin[1]-_plyr.origin[1],origin[3]-_plyr.origin[3])
          -- boost repulsive force
          if(force<0) force*=8
          local vx,vz=vel[1]-force*cos(a),vel[3]-force*sin(a)
          if force>0 then
            -- limit attraction velocity
            local a=atan2(vx,vz)
            local len=vx*cos(a)+vz*sin(a)
            if len>3 then
              vx*=3/len
              vz*=3/len
            end
          end
          vel[1],vel[3]=vx,vz
        end
      end
      origin=v_add(origin,vel)
      -- on ground?
      if origin[2]<8 then
        origin[2]=8
        vel[2]=0
        on_ground=true
      end
    end
  }))
  grid_register(thing)
  return thing
end

function make_egg(_origin,vel)
  -- spider spawn time
  local ttl=300+rnd(10)
  local thing=add(_things,inherit{
    ent=_entities.egg,
    origin=v_clone(_origin),
    hp=2,
    zangle=0,
    hit=function(_ENV)
      -- avoid reentrancy
      if(dead) return
      hp-=1
      if hp<=0 then
        dead=true   
        grid_unregister(_ENV)
        -- todo: make green goo
        make_blood(origin)
      else
        hit_ttl=5
      end
    end,
    apply=function()
      -- cannot move
    end,
    update=function(_ENV)
      if(dead) return
      ttl-=1
      if ttl<0 then
        dead=true
        make_skull({
          ent=_entities.spider0,
          hp=2,
          on_ground=true,
          apply=function(_ENV,other,force,t)
            if other.ent==ent then
              forces[1]+=t*force[1]
              forces[2]=0
              forces[3]+=t*force[3]
            end
            resolved[other]=true
          end,
          think=function(_ENV)
            -- navigate to target
            local dir=v_dir(origin,_plyr.origin)
            forces=v_add(forces,dir,8+seed*cos(time()/5))
          end
        },origin)
      end
    end
  })
  grid_register(thing)
end

function make_blood(_origin)  
  local ents={
    _entities.blood0,
    _entities.blood1,
    _entities.blood2
  }
  local thing=add(_things,setmetatable({
    -- sprite id
    ent=_entities.blood0,
    origin=_origin,
    -- random aspect
    zangle=rnd(),
    yangle=0,
    ttl=0,
    shadeless=true,
    update=function(_ENV)
      ttl+=1
      if(ttl>15) dead=true return
      ent=ents[min(ttl\5+1,#ents)]
      -- assert(ent,"invalid ttl:"..(ttl\5+1))
    end
  },{__index=_ENV}))
  return thing
end

-- draw game world
function draw_world()
  cls(0)
              
  poke4(0x5f38,0x0004.0404)
  for _,chunk in pairs(_sides) do
    draw_poly(chunk,1,2,1)
  end

  poke4(0x5f38,0x0000.0404)
  for _,chunk in pairs(_ground) do
    draw_poly(chunk,1,3,1)
  end        

  -- draw things
  bench_start("draw_grid")
  draw_grid(_cam,1)      
  bench_end()

  -- tilt!
  -- screen = gfx
  -- reset palette
  --memcpy(0x5f00,0x4300,16)
  pal()
  palt(0,false)
  local yshift=8*sin(_cam.tilt)/128
  poke(0x5f54,0x60)
  for i=0,127 do
    sspr(i,0,1,128,i,(i-64)*yshift)
  end
  palt(0,true)
  -- reset
  poke(0x5f54,0x00)
  -- hide trick top/bottom 8 pixel rows :)
  memset(0x6000,0,512)
  memset(0x7e00,0,512)

  local stats={
    BULLETS=_bullets,
    PARTICLE=_particles,
    THINGS=_things,
    FUTURES=_futures
  }
  local s=""
  for k,v in pairs(stats) do
    s..=k.."# "..#v.."\n"
  end
  print(s..stat(0).."kb",2,2,3)

  --bench_print(2,8,7)
end

-- gameplay state
function play_state()
  -- camera & player & misc tables
  _plyr=make_player({512,24,512},0)
  _things,_particles,_bullets,_futures={},{},{},{}
  -- spatial partitioning grid
  _grid=setmetatable({},{
      __index=function(self,k)
        -- automatic creation of buckets
        local t={}
        self[k]=t
        return t
      end
    })

  add(_things,_plyr)

    
  -- make_skull({512,24,512})
  make_worm({512,48,512})
  make_worm({256,48,386})
  
  make_jewel({512,48,512},{0,0,0})

  for i=0,3 do
    local a=i/4
    make_egg({512+32*cos(a),4,512-32*sin(a)},{0,0,0})
  end

  -- enemies
  local skull1={
    ent=_entities.skull,
    hp=2,
    think=function(_ENV)
      -- converge toward player
      if _flying_target then
        local dir=v_dir(origin,_flying_target)
        forces=v_add(forces,dir,8+seed*cos(time()/5))
      end
    end
  }

  local skull2={
    ent=_entities.reaper,
    hp=5,    
    target_ttl=0,
    jewel=true,
    think=function(_ENV)      
      target_ttl-=1
      if target_ttl<0 then  
        -- go opposite from where it stands!  
        local a=atan2(origin[1]-512,origin[3]-512)+0.625-rnd(0.25)
        local r=64+rnd(64)
        target={512+r*cos(a),16+rnd(48),512-r*sin(a)}
        target_ttl=90+rnd(10)
      end
      -- navigate to target
      local dir=v_dir(origin,target)
      forces=v_add(forces,dir,8+seed*cos(time()/5))
    end
  }

  -- scenario
  do_async(function()
    -- circle around player
    while not _plyr.dead do
      local angle=time()/8
      local x,y,z=unpack(_plyr.origin)
      local r=48*cos(angle)
      _flying_target={x+r*cos(angle),y+24+rnd(8),z+r*sin(angle)}
      wait_async(10)
    end

    -- if player dead, find a random spot on map
    while true do
      _flying_target={256+rnd(512),12+rnd(64),256+rnd(512)}
      wait_async(45+rnd(15))
    end
  end)
  -- todo: move to string/table

  do_async(function()
    -- player just spawned
    wait_async(90)
    -- 4 squids
    for i=0,0.75,0.25 do
      local x,z=512+256*cos(i),512-256*sin(i)
      for i=1,8 do
        make_skull(skull1,{x,64,z})
      end
      make_skull(skull2,{x,64,z})
      wait_async(90)
    end
  end)

  return
    -- update
    function()
      _plyr:control()
      
      _cam:track(_plyr.eye_pos,_plyr.m,_plyr.angle,_plyr.tilt)
    end,
    -- draw
    function()
      draw_world()
      -- todo: draw player hand

      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135,0},1)
    end,
    -- init
    function()
      _start_time=time()
    end
end

function test_state()
  local active_ent=_entities.reaper
  local active_pose=0
  local active_angle=0
  return
    -- update
    function()
      if(btnp(0)) active_angle-=1
      if(btnp(1)) active_angle+=1
      if(btnp(2)) active_pose-=1
      if(btnp(3)) active_pose+=1
      active_pose=mid(active_pose,0,4)
      active_angle=mid(active_angle,0,7)
    end,
    -- draw
    function()
      --[[
      local yangle,flipx=active_angle
      if(yangle>4) yangle=4-(yangle%4) flipx=true
      local frame=active_ent.frames[5*active_pose+yangle+1]
      local mem,base=0x0,frame.base
      for i=0,frame.height-1 do
        poke4(mem,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
        mem+=64
        base+=4
      end
      cls()
      fillp(0xa5a5)
      rect(0,0,frame.width,frame.height,1)
      fillp()
      sspr(frame.xmin,0,frame.width,frame.height,0,0,frame.width,frame.height,flipx)

      print("pose: "..active_pose.." angle: "..yangle..(tostr(flipx)).."\nmem: "..stat(0).."\n#sprites:"..#_sprites,2,33,7)
      ]]
      cls()
      local x,y=0,0
      for pose=0,4 do
        for angle=0,4 do
          local frame=active_ent.frames[5*pose+angle+1]
          local mem,base=0x0,frame.base
          for i=0,frame.height-1 do
            poke4(mem,sprites[base],sprites[base+1],sprites[base+2],sprites[base+3])
            mem+=64
            base+=4
          end
          sspr(frame.xmin,0,frame.width,frame.height,x,y,frame.width,frame.height)          
          x+=frame.width
        end
        x=0
        y+=16
      end
      
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 10,0},1)
    end
end

function gameover_state(obituary)  
  local play_time,origin,tilt,deadtilt=time()-_start_time,_plyr.eye_pos,_plyr.tilt,rnd{-0.1,0.1}
  local target=v_add(_plyr.origin,{0,8,0})
  -- leaderboard/retry
  local ttl,selected_tab,over_btn,clicked=90
  local buttons={
    {"rETRY",1,111,cb=function() 
      -- todo: fade to black
      do_async(function()
        for i=0,15 do
          --memcpy(0x5f00,0x4300|i<<4,16)
          yield()
        end
        next_state(play_state)
      end)
    end},
    {"sTATS",1,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        local x=arizona_print("\147 ",1,30,3)
        x=arizona_print(play_time.."S\t ",x,30)
        x=arizona_print("\130 ",x,30,3)
        x=arizona_print(tostr(obituary),x,30)
        --
        local pct=_total_hits==0 and 0 or 1000*(_total_hits/_total_bullets)
        x=arizona_print("\143 ",1,38,3)
        x=arizona_print(_total_jewels.."\t ",x,38)
        x=arizona_print("\134 ",x,38,3)
        x=arizona_print(tostr(_total_bullets,2).."\t ",x,38)
        x=arizona_print("\136 ",x,38,3)
        x=arizona_print((flr(pct)/10).."%",x,38)
      end
    },
    {"lOCAL",46,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        -- todo: local 
        srand(42)
        for i=1,5 do
          arizona_print(i..". "..flr(rnd(1500)),1,23+i*7)
        end
      end},
    {"oNLINE",96,16,
      cb=function(self) selected_tab,clicked=self end,
      draw=function()
        -- todo: online
        srand(42)
        for i=1,5 do
          arizona_print(i..". bOB48 "..flr(rnd(1500)),1,23+i*7)
        end
      end
    }
  }
  -- default (stats)
  selected_tab=buttons[2]
  -- get actual size
  clip(0,0,0,0)
  for _,btn in pairs(buttons) do
    btn.width=print(btn[1])
  end
  clip()
  -- position cursor on retry
  local _,x,y=unpack(buttons[1])
  local mx,my=x+buttons[1].width/2,y+3
  return
    -- update
    function()
      ttl=max(ttl-1)
      tilt=lerp(tilt,deadtilt,0.3)
      origin=v_lerp(origin,target,0.2)
      _cam:track(origin,_plyr.m,_plyr.angle,tilt)
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
        -- darken game screen
        palt(0,false)
        poke(0x5f54,0x60)
        -- shift palette
        memcpy(0x5f00,0x8000|9<<4,16)
        spr(0,0,0,16,16)
        pal()
        -- reset
        poke(0x5f54,0x00)
      
        -- draw menu & all
        arizona_print("hIGHSCORES",1,8)
        for i,btn in pairs(buttons) do
          local s,x,y=unpack(btn)
          arizona_print(s,x,y,selected_tab==btn and 2 or i==over_btn and 1)
        end
        line(unpack(split"1,24,126,24,4"))
        line(unpack(split"1,25,126,25,2"))
        line(unpack(split"1,109,126,109,2"))
        line(unpack(split"1,108,126,108,4"))

        selected_tab:draw()

        -- mouse cursor
        spr(20,mx,my)
      end
      -- hw palette
      pal({128, 130, 133, 5, 134, 6, 7, 136, 8, 138, 139, 3, 131, 1, 135, 0},1)
    end
end

-- pico8 entry points
function _init()
  -- enable custom font
  poke(0x5f58,0x81)

  -- enable tile 0 + extended memory
  poke(0x5f36, 0x18)
  -- capture mouse
  -- enable lock
  poke(0x5f2d,0x7)

  -- exit menu entry
  menuitem(1,"main menu",function()
    -- local version
    load("title.p8")
    -- bbs version
    load("#freds72_daggers_title")
  end)

  -- always needed  
  _cam=make_fps_cam()

  _bullets,_things,_futures={},{},{}
  -- load images
  _entities=decompress("pic",0,0,unpack_entities)
  reload()
  
  -- init ground vectors
  for _,chunk in pairs(_sides) do
    chunk.cp=v_dot(chunk[1],chunk.n)
  end
  for _,chunk in pairs(_ground) do
    chunk.cp=v_dot(chunk[1],chunk.n)
  end

  -- run game
  next_state(play_state)
end

-- collect all grids touched by (a,b) vector
function collect_grid(a,b,u,v,cb)
  local mapx,mapy,mapdx,mapdy=a[1]\32,a[3]\32
  local dest_mapx,dest_mapy=b[1]\32,b[3]\32
  -- check first cell
  cb(mapx>>16|mapy)
  -- early exit
  if dest_mapx==mapx and dest_mapy==mapy then    
    return
  end
  local ddx,ddy,distx,disty=abs(1/u),abs(1/v)
  if u<0 then
    mapdx=-1
    distx=(a[1]/32-mapx)*ddx
  else
    mapdx=1
    distx=(mapx+1-a[1]/32)*ddx
  end
  
  if v<0 then
    mapdy=-1
    disty=(a[3]/32-mapy)*ddy
  else
    mapdy=1
    disty=(mapy+1-a[3]/32)*ddy
  end
  while dest_mapx!=mapx and dest_mapy!=mapy do
    if distx<disty then
      distx+=ddx
      mapx+=mapdx
    else
      disty+=ddy
      mapy+=mapdy
    end
    cb(mapx>>16|mapy)
  end  
end

local _frame=0
function _update()
  -- keep world running    
  local t=time()
  _frame+=1
  -- bullets collisions
  for i=#_bullets,1,-1 do
    local b=_bullets[i]
    if b.ttl<t then
      deli(_bullets,i)
    else
      b.yangle+=0.1
      local prev,origin,len,dead=b.origin,v_add(b.origin,b.velocity,10),10
      -- out of bounds?
      local x,z=origin[1],origin[3]
      if x>64 and x<1024 and z>64 and z<1024 then
        local y=origin[2]
        if y<0 then
          -- hit ground?
          -- intersection with ground
          local dy=prev[2]/(prev[2]-y)
          x,z=lerp(prev[1],x,dy),lerp(prev[3],z,dy)
          origin={x,0,z}
          -- adjust length
          len=v_len(prev,origin)
          -- not matter what - we hit the ground!
          dead=true
          make_blood(origin)
          for i=1,rnd(5) do
            local a=b.zangle+(1-rnd(2))/8
            local cc,ss,r=cos(a),-sin(a),2+rnd(2)
            local o={x+r*cc,0,z+r*ss}
            make_particle(o,{cc,1+rnd(),ss})
          end
        end
        -- collect touched grid indices
        collect_grid(prev,origin,b.u,b.v,function(idx)
          -- todo: advanced bullets can traverse enemies
          local hits=0
          for thing in pairs(_grid[idx]) do
            -- hitable?
            if not thing.dead and thing!=_plyr and thing.hit then
              local hit
              -- edge case: base or tip inside sphere
              -- todo: faster first test (abs)
              if v_len(prev,thing.origin)<16 or v_len(origin,thing.origin)<16 then
                hit=true
                hits+=1
              else
                -- projection on ray
                local t=v_dot(b.velocity,make_v(prev,thing.origin))
                if t>=0 and t<=len then
                  -- distance to sphere?
                  hit=v_len(v_scale(b.velocity,t),thing.origin)<16 
                  hits+=1
                end
              end
              if hit then
                thing:hit()
                dead=true
                _total_hits+=0x0.0001
                -- todo: allow for multiple hits
                break
              end
            end
          end
        end)
      else
        dead=true
      end

      if dead then
        -- hit something?
        deli(_bullets,i)
      else
        b.prev,b.origin=prev,origin
      end
    end
  end
  -- effects
  for i=#_particles,1,-1 do
    local p=_particles[i]
    if p.ttl<t then
      deli(_particles,i)
    else
      local velocity=v_scale(p.velocity,0.8)
      velocity[2]-=0.8
      local origin=v_add(p.origin,velocity,5)
      if origin[2]<0 then
        origin[2]=0
        -- fake rebound
        velocity[2]*=-0.5
      end
      p.prev,p.origin,p.velocity=p.origin,origin,velocity
    end
  end

  bench_start("things")
  for i=#_things,1,-1 do
    local thing=_things[i]
    if thing.dead then
      -- note: assumes thing is already unregistered
      deli(_things,i)
    elseif thing.update then
      thing:update()
    end
  end
  bench_end()

  -- any futures?
  update_asyncs()

  _update_state()
end

-- unpack assets
function unpack_entities()
  local entities,names={},split"skull,reaper,blood0,blood1,blood2,dagger0,dagger1,dagger2,hand0,hand1,hand2,goo0,goo1,goo2,egg,spider0,spider1,worm0,worm1,jewel"
  unpack_array(function()
    local id=mpeek()
    if id!=0 then
      local sprites={}
      entities[names[id]]={  
        sprites=sprites,      
        frames=unpack_frames(sprites)
      }
      printh("restored:"..names[id].." #sprites:"..#sprites)
    end
  end)
  return entities
end

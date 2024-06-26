require("lua_extension")
require("lua_extension_math")
require("renderer/camera")
require("renderer/mesh_filter")
require("renderer/mesh_renderer")
require("renderer/material")
require("renderer/animation")
require("renderer/animation_clip")
require("renderer/skinned_mesh_renderer")
require("renderer/texture_2d")
require("renderer/render_texture")
require("control/input")
require("control/key_code")
require("utils/screen")
require("utils/time")
require("lighting/environment")
require("lighting/point_light")
require("lighting/directional_light")

LoginScene=class("LoginScene",Component)

--- 登录场景
---@class LoginScene
function LoginScene:ctor()
    LoginScene.super.ctor(self)

    self.go_directional_light_left_=nil
    self.go_depth_camera_left_ = nil

    self.go_directional_light_right_=nil
    self.go_depth_camera_right_ = nil

    self.go_camera_ = nil
    ---@field camera_ Camera @场景相机
    self.camera_ = nil

    self.go_skeleton_ = nil --骨骼蒙皮动画物体
    self.animation_ = nil--骨骼动画
    self.animation_clip_ = nil --- 骨骼动画片段
    self.material_plane_ = nil --材质
    self.environment_=nil --环境
    self.go_light_=nil --灯光父节点
    self.go_point_light_1_=nil --灯光
    self.go_point_light_2_=nil --灯光
    self.go_wall_=nil--墙壁
    self.material_wall_=nil
    self.last_frame_mouse_position_=nil--上一帧的鼠标位置
end

function LoginScene:Awake()
    print("LoginScene Awake")
    LoginScene.super.Awake(self)

    self:CreateEnvironment()
    self:CreateLight()

    self:CreateMainCamera()
    self:CreatePlane()
    self:CreateWall()
end

--- 创建环境
function LoginScene:CreateEnvironment()
    self.environment_=Environment.new()
    self.environment_:set_ambient_color(glm.vec3(1.0,1.0,1.0))
    self.environment_:set_ambient_color_intensity(0.3)
end

function LoginScene:CreateLight()
    self.go_light_=GameObject.new("light")
    self.go_light_:AddComponent(Transform)

    self:CreateDirectionalLightLeft()
    self:CreateDirectionalLightRight()
end

--- 创建左边的方向光
function LoginScene:CreateDirectionalLightLeft()
    self.go_directional_light_left_= GameObject.new("directional_light_left")
    local light_transform=self.go_directional_light_left_:AddComponent(Transform)
    light_transform:set_local_position(glm.vec3(0, 0, 10))
    light_transform:set_local_rotation(glm.vec3(0.0,-10.0,0.0))
    local light=self.go_directional_light_left_:AddComponent(DirectionalLight)
    light:set_color(glm.vec3(1.0,1.0,1.0))
    light:set_intensity(1.0)

    self.go_light_:AddChild(self.go_directional_light_left_)

    self.go_depth_camera_left_ = self:CreateDepthCamera("depth_camera_left")
    self.go_directional_light_left_:AddChild(self.go_depth_camera_left_)
end


--- 创建右边的方向光
function LoginScene:CreateDirectionalLightRight()
    self.go_directional_light_right_= GameObject.new("directional_light_right")
    local light_transform=self.go_directional_light_right_:AddComponent(Transform)
    light_transform:set_local_position(glm.vec3(0, 0, 10))
    light_transform:set_local_rotation(glm.vec3(0.0,10.0,0.0))
    local light=self.go_directional_light_right_:AddComponent(DirectionalLight)
    light:set_color(glm.vec3(1.0,1.0,1.0))
    light:set_intensity(1.0)

    self.go_light_:AddChild(self.go_directional_light_right_)

    self.go_depth_camera_right_ = self:CreateDepthCamera("depth_camera_right")
    self.go_directional_light_right_:AddChild(self.go_depth_camera_right_)
end

--- 创建深度相机
function LoginScene:CreateDepthCamera(go_name)
    --创建相机1 GameObject
   local go_depth_camera= GameObject.new(go_name)
    --挂上 Transform 组件
    go_depth_camera:AddComponent(Transform)

    --挂上 Camera 组件
    local depth_camera=go_depth_camera:AddComponent(Camera)
    --设置为黑色背景
    depth_camera:set_clear_color(0,0,0,1)
    depth_camera:set_depth(0)
    depth_camera:SetView(glm.vec3(0.0,0.0,0.0), glm.vec3(0.0,1.0,0.0))
    local camera_size_=10.0
    depth_camera:SetOrthographic(-1*camera_size_, 1*camera_size_, -Screen.aspect_ratio()*camera_size_, Screen.aspect_ratio()*camera_size_, 1.0, 1000.0)

    --设置RenderTexture
    local depth_render_texture_left = RenderTexture.new()
    depth_render_texture_left:Init(960,640)
    depth_camera:set_target_render_texture(depth_render_texture_left)

    return go_depth_camera
end

--- 创建主相机
function LoginScene:CreateMainCamera()
    --创建相机1 GameObject
    self.go_camera_= GameObject.new("main_camera")
    --挂上 Transform 组件
    self.go_camera_:AddComponent(Transform):set_local_position(glm.vec3(0, 0, 50))
    self.go_camera_:GetComponent(Transform):set_local_rotation(glm.vec3(0, 0, 0))
    --挂上 Camera 组件
    self.camera_=self.go_camera_:AddComponent(Camera)
    --设置为黑色背景
    self.camera_:set_clear_color(0,0,0,1)
    self.camera_:set_depth(0)
    self.camera_:SetView(glm.vec3(0.0,0.0,0.0), glm.vec3(0.0,1.0,0.0))
    self.camera_:SetPerspective(60, Screen.aspect_ratio(), 1, 1000)
end

--- 创建模型
function LoginScene:CreatePlane()
    --创建骨骼蒙皮动画
    self.go_skeleton_=GameObject.new("skeleton")
    self.go_skeleton_:AddComponent(Transform):set_local_position(glm.vec3(0, 0, 0))
    self.go_skeleton_:GetComponent(Transform):set_local_rotation(glm.vec3(0, 0, 0))
    local anim_clip_name="animation/fbx_extra_basic_plane_bones_basic_plane_bones_basic_plane_bones_armatureaction_basic_plane_.skeleton_anim"
    self.go_skeleton_:AddComponent(Animation):LoadAnimationClipFromFile(anim_clip_name,"idle")

    local mesh_filter=self.go_skeleton_:AddComponent(MeshFilter)
    mesh_filter:LoadMesh("model/basic_plane_model_basic_plane.mesh")--加载Mesh
    mesh_filter:LoadWeight("model/fbx_extra_basic_plane.weight")--加载权重文件

    --手动创建Material
    self.material_plane_ = Material.new()--设置材质
    self.material_plane_:Parse("material/basic_plane_multi_light.mat")

    --挂上 MeshRenderer 组件
    local skinned_mesh_renderer= self.go_skeleton_:AddComponent(SkinnedMeshRenderer)
    skinned_mesh_renderer:SetMaterial(self.material_plane_)

    --播放动画
    self.go_skeleton_:GetComponent(Animation):Play("idle")
end

---手动创建Mesh
---@return void
function LoginScene:CreateWall()
    local vertex_data={
        -40,-20,0,  1.0,1.0,1.0,1.0, 0,0, -40,-20,1,
         40,-20,0,  1.0,1.0,1.0,1.0, 1,0, 40,-20,1,
         40, 20,0,  1.0,1.0,1.0,1.0, 1,1, 40, 20,1,
        -40, 20,0,  1.0,1.0,1.0,1.0, 0,1, -40, 20,1,
    }
    local vertex_index_data={
        0,1,2,
        0,2,3,
    }

    self.go_wall_=GameObject.new("wall")
    self.go_wall_:AddComponent(Transform):set_local_position(glm.vec3(0, 0, -10))
    self.go_wall_:GetComponent(Transform):set_local_rotation(glm.vec3(0, 0, 0))

    local mesh_filter=self.go_wall_:AddComponent(MeshFilter)
    mesh_filter:CreateMesh(sol2.convert_sequence_float(vertex_data),sol2.convert_sequence_ushort(vertex_index_data))--手动构建Mesh

    --手动创建Material
    self.material_wall_ = Material.new()--设置材质
    self.material_wall_:Parse("material/wall_receive_two_shadow.mat")
    --给Wall设置DepthTexture
    local camera_left=self.go_depth_camera_left_:GetComponent(Camera)
    local render_texture_left=camera_left:target_render_texture()
    self.material_wall_:SetTexture("u_depth_texture_left",render_texture_left:depth_texture_2d())

    local camera_right=self.go_depth_camera_right_:GetComponent(Camera)
    local render_texture_right=camera_right:target_render_texture()
    self.material_wall_:SetTexture("u_depth_texture_right",render_texture_right:depth_texture_2d())

    --挂上 MeshRenderer 组件
    local mesh_renderer= self.go_wall_:AddComponent(MeshRenderer)
    mesh_renderer:SetMaterial(self.material_wall_)
end

function LoginScene:Update()
    --print("LoginScene:Update")
    LoginScene.super.Update(self)

    --设置观察者世界坐标(即相机位置)
    local camera_position=self.go_camera_:GetComponent(Transform):position()
    self.material_plane_:SetUniform3f("u_view_pos",camera_position)
    --设置物体反射度、高光强度
    self.material_plane_:SetUniform1f("u_specular_highlight_shininess",32.0)

    --设置ShadowCamera的参数
    local depth_camera_left=self.go_depth_camera_left_:GetComponent(Camera)
    self.material_wall_:SetUniformMatrix4f("u_shadow_camera_view_left",depth_camera_left:view_mat4())
    self.material_wall_:SetUniformMatrix4f("u_shadow_camera_projection_left",depth_camera_left:projection_mat4())

    local depth_camera_right=self.go_depth_camera_right_:GetComponent(Camera)
    self.material_wall_:SetUniformMatrix4f("u_shadow_camera_view_right",depth_camera_right:view_mat4())
    self.material_wall_:SetUniformMatrix4f("u_shadow_camera_projection_right",depth_camera_right:projection_mat4())

    --鼠标滚轮控制相机远近
    self.go_camera_:GetComponent(Transform):set_local_position(self.go_camera_:GetComponent(Transform):position() *(10 - Input.mouse_scroll())/10)

    --旋转相机
    if Input.GetKeyDown(Cpp.KeyCode.KEY_CODE_LEFT_ALT) and Input.GetMouseButtonDown(Cpp.KeyCode.MOUSE_BUTTON_LEFT) and self.last_frame_mouse_position_ then
        --print(Input.mousePosition(),self.last_frame_mouse_position_)
        local degrees= Input.mousePosition().x - self.last_frame_mouse_position_.x
        self.last_frame_mouse_position_=Input.mousePosition()

        local old_mat4=glm.mat4(1.0)
        local rotate_mat4=glm.rotate(old_mat4,glm.radians(degrees),glm.vec3(0.0,1.0,0.0))--以相机所在坐标系位置，计算用于旋转的矩阵，这里是零点，所以直接用方阵。

        local camera_pos=self.go_camera_:GetComponent(Transform):position()
        local old_pos=glm.vec4(camera_pos.x,camera_pos.y,camera_pos.z,1.0)
        local new_pos=rotate_mat4*old_pos--旋转矩阵 * 原来的坐标 = 相机以零点做旋转。
        --print(new_pos)
        self.go_camera_:GetComponent(Transform):set_local_position(glm.vec3(new_pos.x,new_pos.y,new_pos.z))
    end
    self.last_frame_mouse_position_=Input.mousePosition()
end
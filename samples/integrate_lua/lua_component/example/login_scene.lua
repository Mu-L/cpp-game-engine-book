LoginScene={
    game_object_,
    go_camera_1_,
    go_audio_source_bgm_,
    go_player_,
    camera_1_,
    last_frame_mouse_position_,--上一帧的鼠标位置
    transform_player_= nullptr,
    audio_studio_event_
}

setmetatable(LoginScene,{["__call"]=function(table,param)
    local instance=setmetatable({},{__index=table})
    return instance
end})

-- public:
function LoginScene:Awake()
    --创建相机1 GameObject
    self.go_camera_1_= GameObject("main_camera")
    --挂上 Transform 组件
    self.go_camera_1_:AddComponent("Transform"):set_position(glm.vec3(0, 0, 10))
    --挂上 Camera 组件
    self.camera_1_=self.go_camera_1_:AddComponent("Camera")
    self.camera_1_:set_depth(0)

    self.last_frame_mouse_position_=Input.mousePosition()

    self:CreateAudioSource()
    self:CreateAudioListener()
end

function LoginScene:game_object()
    print("LoginScene:game_object")
    return self.game_object_
end

function LoginScene:set_game_object(game_object)
    print("LoginScene:set_game_object " .. tostring(game_object))
    self.game_object_=game_object
end

function LoginScene:CreateAudioSource()
    self.go_audio_source_bgm_= GameObject("audio_source_bgm")
    --挂上 Transform 组件
    local transform = self.go_audio_source_bgm_:AddComponent("Transform")
    --挂上 MeshFilter 组件
    local mesh_filter= self.go_audio_source_bgm_:AddComponent("MeshFilter")
    mesh_filter:LoadMesh("model/sphere.mesh")
    --挂上 MeshRenderer 组件
    local mesh_renderer= self.go_audio_source_bgm_:AddComponent("MeshRenderer")
    local material = Material()--设置材质
    material:Parse("material/sphere_audio_source_3d_music.mat")
    mesh_renderer:SetMaterial(material)

    --加载bank
    print(AudioStudio.Init())
    AudioStudio.LoadBankFile("audio/test.bank")
    AudioStudio.LoadBankFile("audio/test.strings.bank")
    self.audio_studio_event_=AudioStudio.CreateEventInstance("event:/footstep")
end

function LoginScene:CreateAudioListener()
    self.go_player_= GameObject("Player")
    self.transform_player_ =self.go_player_:AddComponent("Transform")
    self.transform_player_:set_position(glm.vec3(2.0,0.0,0.0))
    local mesh_filter=self.go_player_:AddComponent("MeshFilter")
    mesh_filter:LoadMesh("model/sphere.mesh")
    local mesh_renderer=self.go_player_:AddComponent("MeshRenderer")
    local material = Material()--设置材质
    material:Parse("material/sphere_audio_source_3d_listener.mat")
    mesh_renderer:SetMaterial(material)

    --设置听者位置
    AudioStudio.setListenerAttributes(0,0,0)
end


function LoginScene:Update()
    self.camera_1_:set_depth(0)
    self.camera_1_:SetView(glm.vec3(0.0,0.0,0.0), glm.vec3(0.0,1.0,0.0))
    self.camera_1_:SetProjection(60, Screen.aspect_ratio(), 1, 1000)

    --旋转相机
    if Input.GetKeyDown(KeyCode.KEY_CODE_LEFT_ALT) and Input.GetMouseButtonDown(KeyCode.MOUSE_BUTTON_LEFT) then
        local degrees= Input.mousePosition().x_ - self.last_frame_mouse_position_.x_

        local old_mat4=glm.mat4(1.0)
        local rotate_mat4=glm.rotate(old_mat4,glm.radians(degrees),glm.vec3(0.0,1.0,0.0))--以相机所在坐标系位置，计算用于旋转的矩阵，这里是零点，所以直接用方阵。

        local camera_1_pos=self.go_camera_1_:GetComponent("Transform"):position()
        local old_pos=glm.vec4(camera_1_pos.x,camera_1_pos.y,camera_1_pos.z,1.0)
        local new_pos=rotate_mat4*old_pos--旋转矩阵 * 原来的坐标 = 相机以零点做旋转。
        print(new_pos)
        self.go_camera_1_:GetComponent("Transform"):set_position(glm.vec3(new_pos.x,new_pos.y,new_pos.z))
    end

    --播放Event实例
    if Input.GetKeyUp(KeyCode.KEY_CODE_S) then
        self.audio_studio_event_:Start()
    end

    --按键盘1、2、3设置参数值，切换不同的地面类型，播放不同的脚步声
    if Input.GetKeyUp(KeyCode.KEY_CODE_1) then
        self.audio_studio_event_:SetParameterByName("groundtype",0.0)
    elseif Input.GetKeyUp(KeyCode.KEY_CODE_2) then
        self.audio_studio_event_:SetParameterByName("groundtype",1.0)
    elseif Input.GetKeyUp(KeyCode.KEY_CODE_3) then
        self.audio_studio_event_:SetParameterByName("groundtype",2.0)
    end
    self.last_frame_mouse_position_=Input.mousePosition()

    --鼠标滚轮控制相机远近
    self.go_camera_1_:GetComponent("Transform"):set_position(self.go_camera_1_:GetComponent("Transform"):position() *(10 - Input.mouse_scroll())/10)

    --设置听者位置
    local rotate_mat4=glm.rotate(glm.mat4(1.0),glm.radians(Time.delta_time()*60),glm.vec3(0.0,0.0,1.0))
    local old_player_pos_vec3=self.transform_player_:position()
    local old_player_pos_vec4=glm.vec4(old_player_pos_vec3.x,old_player_pos_vec3.y,old_player_pos_vec3.z,1.0)

    local new_pos_vec4=rotate_mat4 * old_player_pos_vec4--旋转矩阵 * 原来的坐标 = 以零点做旋转。
    self.transform_player_:set_position(glm.vec3(new_pos_vec4.x,new_pos_vec4.y,new_pos_vec4.z))
    AudioStudio.setListenerAttributes(new_pos_vec4.x,new_pos_vec4.y,new_pos_vec4.z)
end
-- @author Qiao-Ziao

local m_Pawn = class("m_Pawn")

-- 私有属性表
local _private = setmetatable({}, {__mode = "k"})

-- 类属性 默认的“移动”和“转面向”时间 默认为1秒
-- 附上getter和setter 此属性不归正规的Get/Set管理
local n_change_time = 1
function m_Pawn:GetChangeTime()
    return n_change_time
end
function m_Pawn:SetChangeTime(v)
    n_change_time = v
end

--! 构造函数 该函数会创建一个新的Pawn对象，并进行初始化操作
-- @param o_pawn_render o_pawn_render的值将赋值给o_object_reference
-- @return void
function m_Pawn:initialize(o_pawn_render)
    --! 成员变量
    --! 公有
    -- @param table 该Pawn具有的所有buff
    self.t_buffs = {}

    --! 私有
    _private[self] = {
        -- @param number Pawn的生命值
        n_health = 0,
        -- @param number Pawn的魔法值
        n_magic = 0,
        -- @param Vector3 Pawn的位置
        v3_position = Vector3(0, 0, 0),
        -- @param Vector3 Pawn的朝向
        ed_face_toward = EulerDegree(0, 0, 0),
        -- @param number Pawn的最大移动能力
        n_max_endurance = 0,
        -- @param number Pawn的可攻击次数
        n_attack_times = 0,
        -- @param object 实例构建时绑定的对象 如果为nil，则绑定在world下的一个cube上
        o_object_reference = o_pawn_render or world:CreateObject("PrimitiveObject", "Cube", world),
        -- @param table 该Pawn实例所属的队伍
        t_team = {}
    }

    -- 更新对象的v3_position 和 ed_face_toward
    _private[self].v3_position = _private[self].o_object_reference.Position
    _private[self].ed_face_toward = _private[self].o_object_reference.Rotation
end

--! 成员函数
--! 公有
-- 获取该Pawn的s_property_name对应的值
-- @param s_property_name 字符串类型的属性名
-- @return auto
function m_Pawn:Get(s_property_name)
    if _private[self][s_property_name] then
        return _private[self][s_property_name]
    elseif self[s_property_name] then
        return self[s_property_name]
    else
        assert(false, "[Error]未检索到名为'" .. s_property_name .. "'的属性")
    end
end

-- 修改属性值
-- @param s_property_name 属性名
-- @param a_value 属性值
-- @return void
function m_Pawn:Set(s_property_name, a_value)
    if _private[self][s_property_name] then
        --! 处理Position和Rotation的变化 默认 n_change_time 秒动画
        if s_property_name == "v3_position" then
            local temp_tween =
                Tween:TweenProperty(
                _private[self].o_object_reference,
                {Position = a_value},
                n_change_time,
                Enum.EaseCurve.QuarticOut
            )
            temp_tween:Play()
        elseif s_property_name == "ed_face_toward" then
            local temp_tween =
                Tween:TweenProperty(
                _private[self].o_object_reference,
                {Rotation = a_value},
                n_change_time,
                Enum.EaseCurve.QuarticOut
            )
            temp_tween:Play()
        end
        -- 检测类型是否合法，合法后执行赋值
        assert(
            type(_private[self][s_property_name]) == type(a_value),
            "[Error]a_value参数类型(" .. type(a_value) .. ")错误，应为:(" .. type(_private[self][s_property_name]) .. ")"
        )
        _private[self][s_property_name] = a_value
    elseif self[s_property_name] then
        -- 检测类型是否合法，合法后执行赋值
        assert(
            type(self[s_property_name]) == type(a_value),
            "[Error]a_value参数类型(" .. type(a_value) .. ")错误，应为:(" .. type(self[s_property_name]) .. ")"
        )
        self[s_property_name] = a_value
    else
        assert(false, "[Error]未检索到名为'" .. s_property_name .. "'的属性")
    end
end

-- 增加属性值
-- @param s_property_name 属性名
-- @param a_delta 属性值
-- @return void
function m_Pawn:Increase(s_property_name, a_delta)
    -- 检测类型是否合法，合法后执行赋值
    assert(
        type(self:Get(s_property_name)) == type(a_delta),
        "[Error]a_delta参数类型(" .. type(a_delta) .. ")错误，应为:(" .. type(self:Get(s_property_name)) .. ")"
    )
    self:Set(s_property_name, self:Get(s_property_name) + a_delta)
end

-- 克隆函数 会基于自身，复制出一个属性完全一致的Pawn实例并返回
-- @return Pawn
function m_Pawn:CloneSelf()
    local return_obj = m_Pawn:new(self:Get("o_object_reference"):Clone(self:Get("o_object_reference").Parent))
    return_obj:Set("t_buffs", self:Get("t_buffs"))
    return_obj:Set("n_health", self:Get("n_health"))
    return_obj:Set("n_magic", self:Get("n_magic"))
    return_obj:Set("v3_position", self:Get("v3_position"))
    return_obj:Set("ed_face_toward", self:Get("ed_face_toward"))
    return_obj:Set("n_max_endurance", self:Get("n_max_endurance"))
    return_obj:Set("n_attack_times", self:Get("n_attack_times"))
    return_obj:Set("t_team", self:Get("t_team"))
    return return_obj
end

-- 克隆函数 静态 会基于p_pawn，复制出一个属性完全一致的Pawn实例并返回
-- @param p_pawn 当p_pawn的类与Pawn存在继承关系时，复制出的Pawn实例，其类与p_pawn的类相同
-- @return Pawn
function m_Pawn.static:Clone(p_pawn)
    return p_pawn:CloneSelf()
end

-- 复制函数 会将传入p_pawn的属性尽可能复制到自身(o_object_reference除外)
-- @param p_pawn 传入的Pawn对象
-- @param t_property
-- 当t_property为空时，复制全部属性
-- 当t_property为表时，复制指定属性
-- @return Pawn
function m_Pawn:Copy(p_pawn, t_property)
    if t_property == nil then
        self:Set("t_buffs", p_pawn:Get("t_buffs"))
        self:Set("n_health", p_pawn:Get("n_health"))
        self:Set("n_magic", p_pawn:Get("n_magic"))
        self:Set("v3_position", p_pawn:Get("v3_position"))
        self:Set("ed_face_toward", p_pawn:Get("ed_face_toward"))
        self:Set("n_max_endurance", p_pawn:Get("n_max_endurance"))
        self:Set("n_attack_times", p_pawn:Get("n_attack_times"))
        self:Set("t_team", p_pawn:Get("t_team"))
    else
        assert(type(t_property) == "table", "[Error]t_property不为空也不为表")
        for _, v in pairs(t_property) do
            self:Set(v, p_pawn:Get(v))
        end
    end
end

-- 测试函数 打印对象的所有属性
-- @return void
function m_Pawn:PrintMsg()
    print("————↓↓↓————")
    print("生命值 / n_health : ", self:Get("n_health"))
    print("魔法值 / n_magic : ", self:Get("n_magic"))
    print("位置 / v3_position : ", self:Get("v3_position"))
    print("面向 / ed_face_toward : ", self:Get("ed_face_toward"))
    print("最大移动力 / n_max_endurance : ", self:Get("n_max_endurance"))
    print("可攻击次数 / n_attack_times : ", self:Get("n_attack_times"))
    print("Buffs / t_buffs : ")
    printTable(self:Get("t_buffs"))
    print("绑定对象 / o_object_reference : ", self:Get("o_object_reference").PathToWorld)
    print("所属队伍 / t_team : ")
    printTable(self:Get("t_team"))
    print("————↑↑↑————")
end

--! 私有
-- 调用该函数时则Pawn实例可以开始行动
-- 该函数默认绑定给Ex_TurnStart
-- @return void
local TurnStart = function()
end

-- 调用该函数则该Pawn实例本回合的行动结束
-- 该函数默认绑定给Ex_TurnEnd
-- @return void
local TurnEnd = function()
end

--! 事件/被动触发
-- 死亡事件，死亡时触发
function m_Pawn:E_OnDead()
end

-- 创造事件，当角色被创造时触发
function m_Pawn:E_OnCreate()
end

-- 移动事件，角色移动时触发
function m_Pawn:E_OnMove(v3_origin_position, v3_target_position)
end

--! 事件/外部主动触发
-- Pawn从起始位置移动到结束位置
-- 默认为等待一小段时间后瞬移，进阶效果由开发者自行继承重载
-- @param v3_origin_position 起始位置
-- @param v3_target_position 目标位置
-- @return void
function m_Pawn:Move(v3_origin_position, v3_target_position)
    --! 建议此处使用Set修改位置
end

-- 行动开始事件，触发后，角色行动开始
function m_Pawn:Ex_TurnStart(p_self)
end

-- 行动结束事件，触发后，角色行动结束
function m_Pawn:Ex_TurnEnd(p_self)
end

-- 移动事件，用于外部调用
-- 触发后，角色会根据传入参数进行移动
-- 该事件默认绑定一个匿名函数，以调用Move函数并触发E_OnMove事件
function m_Pawn:Ex_MoveTo(v3_origin_position, v3_target_position)
end

return m_Pawn

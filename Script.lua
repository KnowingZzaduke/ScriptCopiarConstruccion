local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 40 
local TRANSPARENCIA_MOLDE = 0.5 
local TIEMPO_ESPERA_ENTRE_BLOQUES = 0.01 

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 
local menuAbierto = true

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor (Click para abrir)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 255)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (DISEÑO MEJORADO)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) 
elseif gethui then screenGui.Parent = gethui()
else screenGui.Parent = CoreGui end

-- 1. BOTÓN FLOTANTE (MINIMIZAR/ABRIR)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleMenu"
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0) 
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
toggleBtn.Text = "📐"
toggleBtn.TextSize = 25
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

-- 2. PANEL PRINCIPAL
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 230, 0, 380) 
mainFrame.Position = UDim2.new(0.15, 0, 0.25, 0) 
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- BARRA DE TÍTULO (MOVER)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Text = "🏗️ CONSTRUCTOR PRO"
title.Size = UDim2.new(0.8, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeMini = Instance.new("TextButton")
closeMini.Text = "-"
closeMini.Size = UDim2.new(0.15, 0, 1, 0)
closeMini.Position = UDim2.new(0.85, 0, 0, 0)
closeMini.BackgroundTransparency = 1
closeMini.TextColor3 = Color3.fromRGB(200, 200, 200)
closeMini.TextSize = 20
closeMini.Font = Enum.Font.GothamBold
closeMini.Parent = topBar

-- Input Nombre
local nameInput = Instance.new("TextBox")
nameInput.PlaceholderText = "Nombre archivo..."
nameInput.Size = UDim2.new(0.65, 0, 0, 30)
nameInput.Position = UDim2.new(0.05, 0, 0.12, 0)
nameInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.Parent = mainFrame
Instance.new("UICorner", nameInput)

-- Botón Guardar
local btnSave = Instance.new("TextButton")
btnSave.Text = "💾"
btnSave.Size = UDim2.new(0.2, 0, 0, 30)
btnSave.Position = UDim2.new(0.75, 0, 0.12, 0)
btnSave.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
btnSave.TextColor3 = Color3.new(1,1,1)
btnSave.Parent = mainFrame
Instance.new("UICorner", btnSave)

-- Lista Archivos
local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(0.9, 0, 0.25, 0) 
scrollList.Position = UDim2.new(0.05, 0, 0.22, 0)
scrollList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scrollList.BorderSizePixel = 0
scrollList.Parent = mainFrame
local layoutFiles = Instance.new("UIListLayout")
layoutFiles.Padding = UDim.new(0, 4)
layoutFiles.Parent = scrollList

-- CONTENEDOR ACCIONES
local actionsFrame = Instance.new("Frame")
actionsFrame.Name = "ActionsFrame"
actionsFrame.Size = UDim2.new(0.9, 0, 0.48, 0) 
actionsFrame.Position = UDim2.new(0.05, 0, 0.50, 0) 
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = mainFrame

local layoutActions = Instance.new("UIListLayout")
layoutActions.Padding = UDim.new(0, 6)
layoutActions.SortOrder = Enum.SortOrder.LayoutOrder
layoutActions.Parent = actionsFrame

-- ==========================================
-- 🤏 FUNCIÓN ARRASTRAR
-- ==========================================
local function hacerArrastrable(frameDrag, frameMover)
    local dragging, dragInput, dragStart, startPos
    frameDrag.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frameMover.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frameDrag.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frameMover.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
hacerArrastrable(topBar, mainFrame)

local function toggleGUI()
    menuAbierto = not menuAbierto
    if menuAbierto then
        mainFrame:TweenPosition(UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0.25, 0), "Out", "Quad", 0.3, true)
        toggleBtn.Text = "❌"
    else
        mainFrame:TweenPosition(UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1.5, 0), "In", "Quad", 0.3, true)
        toggleBtn.Text = "📐"
    end
end
toggleBtn.MouseButton1Click:Connect(toggleGUI)
closeMini.MouseButton1Click:Connect(toggleGUI)

-- ==========================================
-- 🧠 LÓGICA & FUNCIONES
-- ==========================================

function notificar(texto)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Constructor", Text=texto, Duration=2})
end

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    local rX, rY, rZ = math.round(x*100)/100, math.round(y*100)/100, math.round(z*100)/100
    return CFrame.new(rX, rY, rZ) * (cf - cf.Position)
end

function actualizarListaArchivos()
    for _, child in pairs(scrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local success, archivos = pcall(function() return listfiles(CARPETA_PRINCIPAL) end)
    if not success then return end
    for _, rutaCompleta in pairs(archivos) do
        local nombreArchivo = rutaCompleta:match("([^/]+)$")
        if nombreArchivo:sub(-5) == ".json" then
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 25)
            itemFrame.BackgroundTransparency = 1
            itemFrame.Parent = scrollList
            
            local btnLoad = Instance.new("TextButton")
            btnLoad.Text = nombreArchivo:sub(1, -6)
            btnLoad.Size = UDim2.new(0.75, 0, 1, 0)
            btnLoad.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btnLoad.TextColor3 = Color3.new(1,1,1)
            btnLoad.Parent = itemFrame
            
            btnLoad.MouseButton1Click:Connect(function()
                local contenido = readfile(rutaCompleta)
                datosGuardados = HttpService:JSONDecode(contenido)
                notificar("📂 Cargado: " .. #datosGuardados .. " objetos")
            end)
            
            local btnDel = Instance.new("TextButton")
            btnDel.Text = "X"
            btnDel.Size = UDim2.new(0.2, 0, 1, 0)
            btnDel.Position = UDim2.new(0.8, 0, 0, 0)
            btnDel.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            btnDel.TextColor3 = Color3.new(1,1,1)
            btnDel.Parent = itemFrame
            btnDel.MouseButton1Click:Connect(function() delfile(rutaCompleta) actualizarListaArchivos() end)
        end
    end
    scrollList.CanvasSize = UDim2.new(0, 0, 0, layoutFiles.AbsoluteContentSize.Y)
end

btnSave.MouseButton1Click:Connect(function()
    if #datosGuardados == 0 then return notificar("⚠️ Vacío") end
    local nombre = nameInput.Text
    if nombre == "" then return notificar("⚠️ Falta nombre") end
    writefile(CARPETA_PRINCIPAL .. "/" .. nombre .. ".json", HttpService:JSONEncode(datosGuardados))
    notificar("💾 Guardado")
    nameInput.Text = ""
    actualizarListaArchivos()
end)

function esBloqueValido(part)
    return part:IsA("BasePart") and part.Name ~= "Baseplate" and part.Transparency < 1 and not part.Parent:FindFirstChild("Humanoid") and not part.Name:find("Ghost_")
end

-- ==========================================
-- 🔄 LÓGICA DE ROTACIÓN INTELIGENTE
-- ==========================================
function obtenerRotacionJugador()
    -- Intenta obtener la rotación del personaje
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        -- Obtenemos el ángulo Y (Yaw) y lo redondeamos a 90 grados
        local x, y, z = hrp.CFrame:ToEulerAnglesYXZ()
        local rotacionSnap = math.round(y / (math.pi/2)) * (math.pi/2)
        return CFrame.Angles(0, rotacionSnap, 0)
    end
    return CFrame.new()
end

function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona un bloque") end
    local centroPart = bloqueSeleccionado
    datosGuardados = {}
    local origenCFrame = centroPart.CFrame
    local count = 0
    for _, part in pairs(workspace:GetDescendants()) do
        if esBloqueValido(part) then
            local dist = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(origenCFrame.Position.X, 0, origenCFrame.Position.Z)).Magnitude
            if dist <= RADIO_HORIZONTAL then
                local cframeRelativo = origenCFrame:Inverse() * part.CFrame
                table.insert(datosGuardados, {Name = part.Name, Color = {part.Color.R, part.Color.G, part.Color.B}, Mat = part.Material.Name, Size = {part.Size.X, part.Size.Y, part.Size.Z}, CF = {cframeRelativo:GetComponents()}})
                count = count + 1
            end
        end
    end
    notificar("✅ Copiados: " .. count)
end

function colocarBloqueReal(nombreItem, cframePosicion)
    -- AQUÍ VA TU EVENTO REMOTO
    print("construir", nombreItem) 
end

function pegarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona destino") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    -- AQUÍ ESTÁ EL CAMBIO CLAVE:
    -- Usamos la posición del bloque seleccionado + la rotación de TU personaje
    local rotacionDeseada = obtenerRotacionJugador()
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position) * rotacionDeseada
    
    notificar("🏗️ Pegando (Sigue tu mirada)...")
    for _, data in pairs(datosGuardados) do
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        
        local ghost = Instance.new("Part")
        ghost.Name = "Ghost_" .. data.Name
        ghost.Size = Vector3.new(unpack(data.Size))
        ghost.CFrame = cframeFinal
        ghost.Color = Color3.new(unpack(data.Color))
        ghost.Material = Enum.Material[data.Mat] or Enum.Material.Plastic
        ghost.Transparency = TRANSPARENCIA_MOLDE
        ghost.Anchored = true
        ghost.CanCollide = false
        ghost.Parent = workspace
        table.insert(fantasmasCreados, ghost)
        
        task.spawn(function() colocarBloqueReal(data.Name, cframeFinal) end)
        if TIEMPO_ESPERA_ENTRE_BLOQUES > 0 then task.wait(TIEMPO_ESPERA_ENTRE_BLOQUES) end
    end
    notificar("✅ Listo")
end

function limpiarFantasmas()
    for _, p in pairs(fantasmasCreados) do if p then p:Destroy() end end
    fantasmasCreados = {}
    bloqueSeleccionado = nil
    highlightBox.Adornee = nil
    notificar("🗑️ Visual limpiado")
end

function vaciarMemoria()
    datosGuardados = {}
    notificar("♻️ Memoria vacía")
end

-- ==========================================
-- 🎮 GENERADOR DE BOTONES
-- ==========================================
local function crearBoton(texto, color, orden, func)
    local btn = Instance.new("TextButton")
    btn.Text = texto
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = orden
    btn.Parent = actionsFrame
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(func)
end

crearBoton("🎯 COPIAR (K)", Color3.fromRGB(0, 150, 100), 1, copiarEstructura)
crearBoton("🏗️ PEGAR (V)", Color3.fromRGB(0, 100, 200), 2, pegarEstructura)
crearBoton("🧹 LIMPIAR VISUAL (X)", Color3.fromRGB(200, 120, 0), 3, limpiarFantasmas)
crearBoton("♻️ VACIAR MEMORIA (Z)", Color3.fromRGB(150, 0, 0), 4, vaciarMemoria)

tool.Equipped:Connect(function(mouse)
    actualizarListaArchivos()
    mouse.Button1Down:Connect(function()
        if mouse.Target and esBloqueValido(mouse.Target) then
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            notificar("🎯 " .. bloqueSeleccionado.Name)
        end
    end)
    mouse.KeyDown:Connect(function(key)
        key = key:lower()
        if key == "k" then copiarEstructura()
        elseif key == "v" then pegarEstructura()
        elseif key == "x" then limpiarFantasmas()
        elseif key == "z" then vaciarMemoria()
        end
    end)
end)

tool.Unequipped:Connect(function() highlightBox.Adornee = nil bloqueSeleccionado = nil end)
actualizarListaArchivos()
notificar("✅ Script v4.0 (Rotación Automática)")

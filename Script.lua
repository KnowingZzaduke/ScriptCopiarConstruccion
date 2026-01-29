local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- ⚙️ CONFIGURACIÓN Y CARPETAS
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 40 
local TRANSPARENCIA_MOLDE = 0.5 
local TIEMPO_ESPERA_ENTRE_BLOQUES = 0.02 

-- Crear carpeta de forma segura
if not isfolder(CARPETA_PRINCIPAL) then 
    makefolder(CARPETA_PRINCIPAL) 
end

-- Variables de estado
local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor Universal (PC/Mobile)"
tool.Parent = LocalPlayer.Backpack

-- Visualizador de selección
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 255)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (VISUAL MEJORADA PARA DELTA)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
-- Intento de protección compatible con varios executors
if syn and syn.protect_gui then 
    syn.protect_gui(screenGui) 
elseif gethui then
    screenGui.Parent = gethui()
else
    screenGui.Parent = CoreGui
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 420) -- Un poco más alto para los botones móviles
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0) -- Posición inicial amigable para móvil
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- ¡IMPORTANTE! Permite moverlo con el dedo en Delta
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Título
local title = Instance.new("TextLabel")
title.Text = "🏗️ CONSTRUCTOR XENO/DELTA"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = mainFrame

-- Input Nombre
local nameInput = Instance.new("TextBox")
nameInput.PlaceholderText = "Nombre archivo..."
nameInput.Size = UDim2.new(0.65, 0, 0, 30)
nameInput.Position = UDim2.new(0.05, 0, 0.08, 0)
nameInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.Parent = mainFrame
Instance.new("UICorner", nameInput)

-- Botón Guardar
local btnSave = Instance.new("TextButton")
btnSave.Text = "💾"
btnSave.Size = UDim2.new(0.2, 0, 0, 30)
btnSave.Position = UDim2.new(0.75, 0, 0.08, 0)
btnSave.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
btnSave.TextColor3 = Color3.new(1,1,1)
btnSave.Parent = mainFrame
Instance.new("UICorner", btnSave)

-- Lista Archivos
local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(0.9, 0, 0.4, 0)
scrollList.Position = UDim2.new(0.05, 0, 0.18, 0)
scrollList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scrollList.BorderSizePixel = 0
scrollList.Parent = mainFrame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = scrollList

-- SECCIÓN DE ACCIONES (NUEVO PARA MÓVIL)
local actionsFrame = Instance.new("Frame")
actionsFrame.Name = "ActionsFrame"
actionsFrame.Size = UDim2.new(0.9, 0, 0.25, 0)
actionsFrame.Position = UDim2.new(0.05, 0, 0.60, 0)
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = mainFrame

local function crearBotonAccion(texto, color, orden, callback)
    local btn = Instance.new("TextButton")
    btn.Text = texto
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.Position = UDim2.new(0, 0, 0, (orden-1)*30)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = actionsFrame
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(callback)
end

-- Botón Limpiar (Separado abajo)
local btnLimpiar = Instance.new("TextButton")
btnLimpiar.Text = "🧹 LIMPIAR VISUAL (X)"
btnLimpiar.Size = UDim2.new(0.9, 0, 0, 30)
btnLimpiar.Position = UDim2.new(0.05, 0, 0.9, 0)
btnLimpiar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
btnLimpiar.TextColor3 = Color3.new(1,1,1)
btnLimpiar.Font = Enum.Font.GothamBold
btnLimpiar.Parent = mainFrame
Instance.new("UICorner", btnLimpiar)

-- ==========================================
-- 🧠 LÓGICA & FUNCIONES
-- ==========================================

function notificar(texto)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Constructor";
        Text = texto;
        Duration = 2;
    })
end

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    local rX, rY, rZ = math.round(x*100)/100, math.round(y*100)/100, math.round(z*100)/100
    return CFrame.new(rX, rY, rZ) * (cf - cf.Position)
end

function actualizarListaArchivos()
    for _, child in pairs(scrollList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
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
                notificar("📂 Cargado: " .. #datosGuardados .. " objetos.")
            end)
            
            local btnDel = Instance.new("TextButton")
            btnDel.Text = "X"
            btnDel.Size = UDim2.new(0.2, 0, 1, 0)
            btnDel.Position = UDim2.new(0.8, 0, 0, 0)
            btnDel.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            btnDel.TextColor3 = Color3.new(1,1,1)
            btnDel.Parent = itemFrame
            
            btnDel.MouseButton1Click:Connect(function()
                delfile(rutaCompleta)
                actualizarListaArchivos()
            end)
        end
    end
    scrollList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

btnSave.MouseButton1Click:Connect(function()
    if #datosGuardados == 0 then return notificar("⚠️ Nada para guardar") end
    local nombre = nameInput.Text
    if nombre == "" then return notificar("⚠️ Pon un nombre") end
    writefile(CARPETA_PRINCIPAL .. "/" .. nombre .. ".json", HttpService:JSONEncode(datosGuardados))
    notificar("💾 Guardado")
    nameInput.Text = ""
    actualizarListaArchivos()
end)

-- LOGICA DE COPIA
function esBloqueValido(part)
    return part:IsA("BasePart") 
        and part.Name ~= "Baseplate" 
        and part.Transparency < 1 
        and not part.Parent:FindFirstChild("Humanoid") 
        and not part.Name:find("Ghost_")
end

function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ ¡Selecciona un bloque primero!") end
    
    local centroPart = bloqueSeleccionado
    datosGuardados = {}
    local origenCFrame = centroPart.CFrame
    local count = 0
    
    for _, part in pairs(workspace:GetDescendants()) do
        if esBloqueValido(part) then
            local dist = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(origenCFrame.Position.X, 0, origenCFrame.Position.Z)).Magnitude
            
            if dist <= RADIO_HORIZONTAL then
                local cframeRelativo = origenCFrame:Inverse() * part.CFrame
                table.insert(datosGuardados, {
                    Name = part.Name,
                    Color = {part.Color.R, part.Color.G, part.Color.B},
                    Mat = part.Material.Name,
                    Size = {part.Size.X, part.Size.Y, part.Size.Z},
                    CF = {cframeRelativo:GetComponents()} 
                })
                count = count + 1
            end
        end
    end
    notificar("✅ Copiados " .. count .. " objetos.")
end

-- LOGICA DE PEGADO
function colocarBloqueReal(nombreItem, cframePosicion)
    -- ⚠️⚠️⚠️ AQUI VA TU REMOTE EVENT ⚠️⚠️⚠️
    -- En móvil o PC, esto es lo que realmente construye.
    -- Ejemplo:
    -- game:GetService("ReplicatedStorage").Remotes.Place:FireServer(unpack({[1]="Place", [2]=nombreItem, [3]=cframePosicion}))
    print("🔨 [CONSTRUIR]: " .. nombreItem)
end

function pegarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ ¡Selecciona donde pegar!") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    local nuevoCentroCFrame = bloqueSeleccionado.CFrame
    notificar("🏗️ Construyendo...")
    
    for _, data in pairs(datosGuardados) do
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        
        -- Fantasma Visual
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
        
        -- Construcción Real
        task.spawn(function()
            colocarBloqueReal(data.Name, cframeFinal)
        end)
        
        if TIEMPO_ESPERA_ENTRE_BLOQUES > 0 then task.wait(TIEMPO_ESPERA_ENTRE_BLOQUES) end
    end
    notificar("✅ Terminado")
end

function limpiarFantasmas()
    for _, p in pairs(fantasmasCreados) do if p then p:Destroy() end end
    fantasmasCreados = {}
    bloqueSeleccionado = nil
    highlightBox.Adornee = nil
    notificar("🗑️ Limpio")
end

-- ==========================================
-- 🎮 VINCULACIÓN DE CONTROLES (PC & MOVIL)
-- ==========================================

-- 1. Crear botones para Delta (Móvil)
crearBotonAccion("🎯 COPIAR (K)", Color3.fromRGB(0, 150, 100), 1, copiarEstructura)
crearBotonAccion("🏗️ PEGAR (V)", Color3.fromRGB(0, 100, 200), 2, pegarEstructura)
btnLimpiar.MouseButton1Click:Connect(limpiarFantasmas)

-- 2. Lógica de Herramienta
tool.Equipped:Connect(function(mouse)
    actualizarListaArchivos()
    
    -- Click/Touch para seleccionar bloque central
    mouse.Button1Down:Connect(function()
        if mouse.Target and esBloqueValido(mouse.Target) then
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            notificar("🎯 Seleccionado: " .. bloqueSeleccionado.Name)
        end
    end)
    
    -- Teclado físico (Solo PC)
    mouse.KeyDown:Connect(function(key)
        key = key:lower()
        if key == "k" then copiarEstructura()
        elseif key == "v" then pegarEstructura()
        elseif key == "x" then limpiarFantasmas()
        end
    end)
end)

tool.Unequipped:Connect(function()
    highlightBox.Adornee = nil
    bloqueSeleccionado = nil
end)

actualizarListaArchivos()
notificar("✅ Script Cargado (PC/Delta)")

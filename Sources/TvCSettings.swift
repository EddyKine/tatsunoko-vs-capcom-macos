import SwiftUI
import AppKit

struct ResolutionOption: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    init(_ id: String, _ title: String, _ detail: String) {
        self.id = id; self.title = title; self.detail = detail
    }
}

struct CRTOption: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let shaderName: String?
    init(_ id: String, _ title: String, _ detail: String, shaderName: String? = nil) {
        self.id = id; self.title = title; self.detail = detail; self.shaderName = shaderName
    }
}

struct SaveProfile: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let url: URL
    let isBackup: Bool
}

struct ControllerActionOption: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

struct XboxButtonOption: Identifiable, Hashable {
    let id: String
    let title: String
    let token: String
}

enum MainTab: String, CaseIterable, Identifiable {
    case general = "General"
    case controller = "Control Xbox"
    case saves = "Partidas"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .controller: return "gamecontroller.fill"
        case .saves: return "externaldrive.fill.badge.timemachine"
        }
    }
}

@MainActor
final class ConfigManager: ObservableObject {
    static let resolutions: [ResolutionOption] = [
        .init("640x528", "Nativa Wii (1×)", "640 × 528 EFB · salida escalada al monitor"),
        .init("1280x720", "720p (2×)", "Escala interna 2×"),
        .init("1920x1080", "1080p (3×)", "Escala interna 3× · recomendado"),
        .init("2560x1440", "1440p (4×)", "Escala interna 4× · alta nitidez"),
        .init("3840x2160", "4K (6×)", "Escala interna 6× · alta resolución"),
        .init("5120x2880", "5K (8×)", "Escala interna 8× · experimental"),
        .init("7680x4320", "8K (12×)", "Escala interna 12× · experimental")
    ]

    static let baseCRTOptions: [CRTOption] = [
        .init("off", "Desactivado", "Imagen limpia, sin post-procesado CRT"),
        .init("soft", "CRT · scanlines suaves", "Líneas finas bloqueadas a píxel · recomendado", shaderName: "TvC_CRT_Adaptive_Soft"),
        .init("strong", "CRT · scanlines marcadas", "Una línea oscura por grupo · contraste arcade", shaderName: "TvC_CRT_Adaptive_Strong")
    ]

    static let controllerActions: [ControllerActionOption] = [
        .init(id: "none", title: "Libre", detail: "El botón queda libre"),
        .init(id: "wii1", title: "Ataque normal", detail: "Wii 1 · ataque normal"),
        .init(id: "wii2", title: "Ataque especial", detail: "Wii 2 · ataque especial"),
        .init(id: "partner", title: "Partner / Assist", detail: "Wii B · compañero"),
        .init(id: "megacrash", title: "Mega Crash", detail: "Wii A · Mega Crash"),
        .init(id: "taunt", title: "Provocación", detail: "Wii − · provocación"),
        .init(id: "pause", title: "Pausa", detail: "Wii + · menú de pausa"),
        .init(id: "home", title: "HOME", detail: "Botón HOME de Wii")
    ]

    static let classicControllerActions: [ControllerActionOption] = [
        .init(id: "none", title: "Libre", detail: "Sin asignación"),
        .init(id: "classicY", title: "Classic Y", detail: "Ataque ligero"),
        .init(id: "classicX", title: "Classic X", detail: "Ataque medio"),
        .init(id: "classicA", title: "Classic A", detail: "Ataque fuerte / Confirmar"),
        .init(id: "classicB", title: "Classic B", detail: "Partner / Cancelar"),
        .init(id: "classicL", title: "Classic L", detail: "Ataque fuerte"),
        .init(id: "classicR", title: "Classic R", detail: "Ligero + Medio + Fuerte"),
        .init(id: "classicMinus", title: "Classic −", detail: "Taunt"),
        .init(id: "classicPlus", title: "Classic +", detail: "Pausa"),
        .init(id: "classicHome", title: "Classic HOME", detail: "Menú HOME")
    ]

    static let xboxButtons: [XboxButtonOption] = [
        .init(id: "A", title: "A", token: "`Button S`"),
        .init(id: "B", title: "B", token: "`Button E`"),
        .init(id: "X", title: "X", token: "`Button W`"),
        .init(id: "Y", title: "Y", token: "`Button N`"),
        .init(id: "LB", title: "LB", token: "`Shoulder L`"),
        .init(id: "RB", title: "RB", token: "`Shoulder R`"),
        .init(id: "LT", title: "LT", token: "`Trigger L`"),
        .init(id: "RT", title: "RT", token: "`Trigger R`"),
        .init(id: "View", title: "View", token: "Back"),
        .init(id: "Menu", title: "Menu", token: "Start"),
        .init(id: "Guide", title: "Xbox", token: "Guide")
    ]

    @Published var selectedResolution = "1920x1080"
    @Published var fullscreen = false
    @Published var selectedCRT = "off"
    @Published var backendConfigName = "No especificado"
    @Published var controllerName = "Perfil existente"
    @Published var statusText = "Buscando UserData…"
    @Published var configFound = false
    @Published var canLaunchGame = false
    @Published var hasUnsavedChanges = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var externalShaderName = ""

    @Published var saveFound = false
    @Published var saveStatusText = "Buscando partida…"
    @Published var saveProfiles: [SaveProfile] = []
    @Published var selectedSaveProfileID = ""

    @Published var controllerConfigFound = false
    @Published var controllerStatusText = "Buscando mapeo…"
    @Published var controllerBindings: [String: String] = [:]
    @Published var classicControllerBindings: [String: String] = [:]
    @Published var controllerHasUnsavedChanges = false
    @Published var selectedControllerProfile = "classic_tvc"

    @Published var isGameRunning = false
    @Published var forceQuitSuggested = false

    private var originalText = ""
    private var crtChanged = false

    var portableRoot: URL { Bundle.main.bundleURL.deletingLastPathComponent() }
    var userDataURL: URL { portableRoot.appendingPathComponent("UserData", isDirectory: true) }
    var configURL: URL { userDataURL.appendingPathComponent("config.ini") }
    var backupURL: URL { userDataURL.appendingPathComponent("config.ini.bak") }
    var gfxConfigURL: URL { userDataURL.appendingPathComponent("Config/GFX.ini") }
    var gfxBackupURL: URL { userDataURL.appendingPathComponent("Config/GFX.ini.tvc-settings.bak") }
    var wiimoteConfigURL: URL { userDataURL.appendingPathComponent("Config/WiimoteNew.ini") }
    var shadersURL: URL { userDataURL.appendingPathComponent("Shaders", isDirectory: true) }
    var gameURL: URL { portableRoot.appendingPathComponent("Tatsunoko vs Capcom.app", isDirectory: true) }

    var controllerProfilesRootURL: URL { userDataURL.appendingPathComponent("TvC Controller Profiles", isDirectory: true) }
    var controllerOriginalURL: URL { controllerProfilesRootURL.appendingPathComponent("Original/WiimoteNew.ini") }
    var controllerBackupsURL: URL { controllerProfilesRootURL.appendingPathComponent("Backups", isDirectory: true) }

    var activeSaveURL: URL { userDataURL.appendingPathComponent("Wii/title/00010000/53544b45", isDirectory: true) }
    var saveProfilesRootURL: URL { userDataURL.appendingPathComponent("TvC Save Profiles", isDirectory: true) }
    var saveBackupsURL: URL { saveProfilesRootURL.appendingPathComponent("Backups", isDirectory: true) }
    var importedProfilesURL: URL { saveProfilesRootURL.appendingPathComponent("Imported", isDirectory: true) }

    var selectedOption: ResolutionOption {
        Self.resolutions.first(where: { $0.id == selectedResolution }) ?? Self.resolutions[2]
    }
    var crtOptions: [CRTOption] {
        var result = Self.baseCRTOptions
        if !externalShaderName.isEmpty { result.append(.init("external", "Shader externo detectado", externalShaderName)) }
        return result
    }
    var selectedCRTOption: CRTOption { crtOptions.first(where: { $0.id == selectedCRT }) ?? Self.baseCRTOptions[0] }
    var selectedSaveProfile: SaveProfile? { saveProfiles.first(where: { $0.id == selectedSaveProfileID }) }
    var portableLocationText: String { portableRoot.lastPathComponent }

    func load() {
        configFound = FileManager.default.fileExists(atPath: configURL.path)
        canLaunchGame = FileManager.default.fileExists(atPath: gameURL.path)
        refreshGameRunningState()
        loadSaveState()
        loadControllerMapping()
        loadCRTState()

        guard configFound else {
            statusText = "No se encontró UserData/config.ini"
            return
        }
        do {
            originalText = try String(contentsOf: configURL, encoding: .utf8)
            if let value = value(forKey: "resolution", in: originalText), Self.resolutions.contains(where: { $0.id.caseInsensitiveCompare(value)  == ComparisonResult.orderedSame }) {
                selectedResolution = value.lowercased()
            }
            if let value = value(forKey: "fullscreen", in: originalText) { fullscreen = parseBool(value) }
            backendConfigName = value(forKey: "backend", in: originalText) ?? "No especificado"
            controllerName = readControllerProfile(from: originalText)
            statusText = "Configuración cargada"
            hasUnsavedChanges = false
            crtChanged = false
        } catch {
            statusText = "No se pudo leer config.ini"
            presentError("Error al leer la configuración", error.localizedDescription)
        }
    }

    func markChanged() { hasUnsavedChanges = true }
    func markCRTChanged() { crtChanged = true; hasUnsavedChanges = true }

    func restoreRecommended() {
        selectedResolution = "1920x1080"
        fullscreen = false
        selectedCRT = "off"
        crtChanged = true
        hasUnsavedChanges = true
    }

    func save() -> Bool {
        guard configFound else {
            presentError("No se encontró la configuración", "TvC Settings debe estar dentro de la misma carpeta portable que UserData y Tatsunoko vs Capcom.app.")
            return false
        }
        do {
            let current = try String(contentsOf: configURL, encoding: .utf8)
            var updated = replacingValue(forKey: "resolution", with: selectedResolution, in: current)
            updated = replacingValue(forKey: "fullscreen", with: fullscreen ? "true" : "false", in: updated)
            try? FileManager.default.removeItem(at: backupURL)
            try FileManager.default.copyItem(at: configURL, to: backupURL)
            try updated.write(to: configURL, atomically: true, encoding: .utf8)
            if crtChanged { try saveCRTConfiguration() }
            else if let shader = selectedCRTOption.shaderName { try installShader(named: shader) }
            originalText = updated
            backendConfigName = value(forKey: "backend", in: updated) ?? "No especificado"
            hasUnsavedChanges = false
            crtChanged = false
            statusText = "Cambios guardados"
            return true
        } catch {
            statusText = "No se pudo guardar"
            presentError("Error al guardar", error.localizedDescription)
            return false
        }
    }

    func launchGame() {
        if hasUnsavedChanges && !save() { return }
        guard canLaunchGame else {
            presentError("No se encontró el juego", "No aparece Tatsunoko vs Capcom.app junto a TvC Settings.app.")
            return
        }
        let cfg = NSWorkspace.OpenConfiguration(); cfg.activates = true
        NSWorkspace.shared.openApplication(at: gameURL, configuration: cfg) { _, error in
            Task { @MainActor in
                if let error { self.presentError("No se pudo abrir el juego", error.localizedDescription) }
                else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.refreshGameRunningState() }
                }
            }
        }
    }

    func refreshGameRunningState() {
        isGameRunning = runningGameApplication() != nil
        if !isGameRunning { forceQuitSuggested = false }
    }

    private func runningGameApplication() -> NSRunningApplication? {
        let target = gameURL.resolvingSymlinksInPath().standardizedFileURL
        return NSWorkspace.shared.runningApplications.first { app in
            guard let url = app.bundleURL?.resolvingSymlinksInPath().standardizedFileURL else { return false }
            return url == target
        }
    }

    func stopGame(force: Bool) {
        guard let app = runningGameApplication() else { refreshGameRunningState(); return }
        if force {
            if !app.forceTerminate() { presentError("No se pudo forzar el cierre", "macOS no aceptó la solicitud de cierre forzado para esta copia del juego.") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.refreshGameRunningState() }
            return
        }
        _ = app.terminate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.refreshGameRunningState()
            if self.isGameRunning {
                self.forceQuitSuggested = true
                self.presentError("El juego no respondió", "El cierre normal fue rechazado. Puedes usar FORZAR CIERRE desde la barra inferior.")
            }
        }
    }

    // MARK: - Controller

    func loadControllerMapping() {
        controllerConfigFound = FileManager.default.fileExists(atPath: wiimoteConfigURL.path)
        controllerBindings = defaultLegacyBindings()
        classicControllerBindings = defaultClassicBindings()
        selectedControllerProfile = "classic_tvc"

        guard let text = try? String(contentsOf: wiimoteConfigURL, encoding: .utf8) else {
            controllerStatusText = "WiimoteNew.ini no encontrado"
            controllerHasUnsavedChanges = false
            return
        }

        try? createControllerOriginalIfNeeded()

        if isClassicProfile(text) {
            selectedControllerProfile = "classic_tvc"
            let values = classicControllerValues(in: text)
            for button in Self.xboxButtons {
                classicControllerBindings[button.id] = classicActionID(forToken: button.token, values: values)
            }
            controllerStatusText = "Classic Controller TvC cargado"
        } else {
            selectedControllerProfile = "legacy_custom"
            let values = controllerValues(in: text)
            for button in Self.xboxButtons {
                controllerBindings[button.id] = actionID(forToken: button.token, values: values)
            }
            controllerStatusText = "Mapeo Xbox · Wiimote horizontal cargado"
        }

        controllerHasUnsavedChanges = false
    }

    func setControllerProfile(_ profile: String) {
        selectedControllerProfile = profile
        if profile == "legacy_custom" && controllerBindings.isEmpty {
            controllerBindings = defaultLegacyBindings()
        }
        if profile == "classic_tvc" && classicControllerBindings.isEmpty {
            classicControllerBindings = defaultClassicBindings()
        }
        controllerHasUnsavedChanges = true
    }

    func setControllerBinding(buttonID: String, actionID: String) {
        if actionID != "none" {
            for key in controllerBindings.keys where key != buttonID && controllerBindings[key] == actionID {
                controllerBindings[key] = "none"
            }
        }
        controllerBindings[buttonID] = actionID
        controllerHasUnsavedChanges = true
    }

    func setClassicControllerBinding(buttonID: String, actionID: String) {
        if actionID != "none" {
            for key in classicControllerBindings.keys where key != buttonID && classicControllerBindings[key] == actionID {
                classicControllerBindings[key] = "none"
            }
        }
        classicControllerBindings[buttonID] = actionID
        controllerHasUnsavedChanges = true
    }

    func restoreRecommendedClassicMapping() {
        selectedControllerProfile = "classic_tvc"
        classicControllerBindings = defaultClassicBindings()
        controllerHasUnsavedChanges = true
        controllerStatusText = "Perfil Classic TvC recomendado listo para guardar"
    }

    func actionTitle(forButton id: String) -> String {
        let action = controllerBindings[id] ?? "none"
        return Self.controllerActions.first(where: { $0.id == action })?.title ?? "Libre"
    }

    func classicActionTitle(forButton id: String) -> String {
        let action = classicControllerBindings[id] ?? "none"
        return Self.classicControllerActions.first(where: { $0.id == action })?.detail ?? "Libre"
    }

    func activeActionTitle(forButton id: String) -> String {
        if selectedControllerProfile == "classic_tvc" {
            return classicActionTitle(forButton: id)
        }
        let action = controllerBindings[id] ?? "none"
        return Self.controllerActions.first(where: { $0.id == action })?.detail ?? "Libre"
    }

    func activeActionID(forButton id: String) -> String {
        selectedControllerProfile == "classic_tvc" ? (classicControllerBindings[id] ?? "none") : (controllerBindings[id] ?? "none")
    }

    func saveControllerMapping() {
        guard controllerConfigFound || FileManager.default.fileExists(atPath: userDataURL.path) else {
            presentError("No se encontró el mapeo", "Falta UserData/Config/WiimoteNew.ini.")
            return
        }

        do {
            let fm = FileManager.default
            try fm.createDirectory(at: wiimoteConfigURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try createControllerOriginalIfNeeded()
            if fm.fileExists(atPath: wiimoteConfigURL.path) {
                try createControllerBackup(prefix: "Antes_de_guardar")
            }

            let device = currentControllerDevice()
            let text = selectedControllerProfile == "classic_tvc" ? classicProfile(device: device) : legacyProfile(device: device)
            guard validateControllerMappingText(text) else {
                throw NSError(domain: "TvCSettings", code: 31, userInfo: [NSLocalizedDescriptionKey: "La validación previa del mapeo falló. No se modificó WiimoteNew.ini."])
            }

            let previous = try? Data(contentsOf: wiimoteConfigURL)
            try text.write(to: wiimoteConfigURL, atomically: true, encoding: .utf8)
            let check = try String(contentsOf: wiimoteConfigURL, encoding: .utf8)
            if !validateControllerMappingText(check) {
                if let previous {
                    try previous.write(to: wiimoteConfigURL, options: .atomic)
                }
                throw NSError(domain: "TvCSettings", code: 32, userInfo: [NSLocalizedDescriptionKey: "La verificación posterior al guardado falló. Se restauró automáticamente el archivo anterior."])
            }

            controllerConfigFound = true
            controllerHasUnsavedChanges = false
            controllerStatusText = selectedControllerProfile == "classic_tvc" ? "Classic Controller TvC guardado y verificado" : "Mapeo guardado y verificado"
        } catch {
            presentError("No se pudo guardar el mapeo", error.localizedDescription)
        }
    }

    func restoreControllerOriginal() {
        guard FileManager.default.fileExists(atPath: controllerOriginalURL.path) else {
            presentError("No existe un original guardado", "TvC Settings todavía no tiene una copia original de WiimoteNew.ini.")
            return
        }

        do {
            if FileManager.default.fileExists(atPath: wiimoteConfigURL.path) {
                try createControllerBackup(prefix: "Antes_de_restaurar")
            }
            let data = try Data(contentsOf: controllerOriginalURL)
            try FileManager.default.createDirectory(at: wiimoteConfigURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: wiimoteConfigURL, options: .atomic)
            loadControllerMapping()
            controllerStatusText = "Mapeo original restaurado"
        } catch {
            presentError("No se pudo restaurar el mapeo", error.localizedDescription)
        }
    }

    private func defaultLegacyBindings() -> [String: String] {
        [
            "A": "wii2", "B": "partner", "X": "wii1", "Y": "megacrash",
            "LB": "none", "RB": "none", "LT": "none", "RT": "none",
            "View": "taunt", "Menu": "pause", "Guide": "home"
        ]
    }

    private func defaultClassicBindings() -> [String: String] {
        [
            "A": "classicA",
            "B": "classicB",
            "X": "classicY",
            "Y": "classicX",
            "LB": "classicL",
            "RB": "classicR",
            "LT": "none",
            "RT": "none",
            "View": "classicMinus",
            "Menu": "classicPlus",
            "Guide": "classicHome"
        ]
    }

    private func currentControllerDevice() -> String {
        guard
            let text = try? String(contentsOf: wiimoteConfigURL, encoding: .utf8),
            let device = value(forKey: "Device", inSection: "Wiimote1", in: text),
            !device.isEmpty
        else {
            return "SDL/0/Controller"
        }
        return device
    }

    private func isClassicProfile(_ text: String) -> Bool {
        let extensionName = value(forKey: "Extension", inSection: "Wiimote1", in: text) ?? ""
        guard extensionName.caseInsensitiveCompare("Classic") == ComparisonResult.orderedSame else {
            return false
        }
        let sideways = value(forKey: "Options/Sideways Wiimote", inSection: "Wiimote1", in: text) ?? "false"
        return !parseBool(sideways)
    }

    private func classicProfile(device: String) -> String {
        func token(for action: String) -> String? {
            guard let buttonID = classicControllerBindings.first(where: { $0.value == action })?.key else {
                return nil
            }
            return Self.xboxButtons.first(where: { $0.id == buttonID })?.token
        }

        let targets: [(String, String)] = [
            ("Classic/Buttons/A", "classicA"),
            ("Classic/Buttons/B", "classicB"),
            ("Classic/Buttons/X", "classicX"),
            ("Classic/Buttons/Y", "classicY"),
            ("Classic/Triggers/L", "classicL"),
            ("Classic/Triggers/R", "classicR"),
            ("Classic/Buttons/-", "classicMinus"),
            ("Classic/Buttons/+", "classicPlus"),
            ("Classic/Buttons/Home", "classicHome")
        ]

        var out = "[Wiimote1]\n\nDevice = \(device)\n\nExtension = Classic\nOptions/Sideways Wiimote = False\n\n"
        for (key, action) in targets {
            if let value = token(for: action) {
                out += "\(key) = \(value)\n"
            }
        }

        out += """

        Classic/D-Pad/Up = `Pad N`
        Classic/D-Pad/Down = `Pad S`
        Classic/D-Pad/Left = `Pad W`
        Classic/D-Pad/Right = `Pad E`
        Classic/Left Stick/Up = `Left Y+`
        Classic/Left Stick/Down = `Left Y-`
        Classic/Left Stick/Left = `Left X-`
        Classic/Left Stick/Right = `Left X+`
        """
        return out + "\n"
    }

    private func legacyProfile(device: String) -> String {
        func token(_ action: String) -> String? {
            guard let buttonID = controllerBindings.first(where: { $0.value == action })?.key else {
                return nil
            }
            return Self.xboxButtons.first(where: { $0.id == buttonID })?.token
        }

        var out = "[Wiimote1]\n\nDevice = \(device)\n\n"
        let pairs: [(String, String)] = [
            ("Buttons/A", "megacrash"),
            ("Buttons/B", "partner"),
            ("Buttons/1", "wii1"),
            ("Buttons/2", "wii2"),
            ("Buttons/-", "taunt"),
            ("Buttons/+", "pause"),
            ("Buttons/Home", "home")
        ]
        for (key, action) in pairs {
            if let value = token(action) {
                out += "\(key) = \(value)\n"
            }
        }

        out += """

        D-Pad/Up = `Pad N` | `Left Y+`
        D-Pad/Down = `Pad S` | `Left Y-`
        D-Pad/Left = `Pad W` | `Left X-`
        D-Pad/Right = `Pad E` | `Left X+`
        IR/Up = `Cursor Y-`
        IR/Down = `Cursor Y+`
        IR/Left = `Cursor X-`
        IR/Right = `Cursor X+`
        Shake/X = `Trigger L`
        Shake/Y = `Trigger R`
        Shake/Z = `Trigger L`
        Rumble/Motor = Motor
        Extension = None
        Options/Sideways Wiimote = True
        """
        return out + "\n"
    }

    private func controllerValues(in text: String) -> [String: String] {
        var result: [String: String] = [:]
        for action in Self.controllerActions where action.id != "none" {
            let key: String
            switch action.id {
            case "wii1": key = "Buttons/1"
            case "wii2": key = "Buttons/2"
            case "partner": key = "Buttons/B"
            case "megacrash": key = "Buttons/A"
            case "taunt": key = "Buttons/-"
            case "pause": key = "Buttons/+"
            case "home": key = "Buttons/Home"
            default: continue
            }
            if let value = value(forKey: key, inSection: "Wiimote1", in: text) {
                result[action.id] = value
            }
        }
        return result
    }

    private func classicControllerValues(in text: String) -> [String: String] {
        let targets: [(String, String)] = [
            ("classicA", "Classic/Buttons/A"),
            ("classicB", "Classic/Buttons/B"),
            ("classicX", "Classic/Buttons/X"),
            ("classicY", "Classic/Buttons/Y"),
            ("classicL", "Classic/Triggers/L"),
            ("classicR", "Classic/Triggers/R"),
            ("classicMinus", "Classic/Buttons/-"),
            ("classicPlus", "Classic/Buttons/+"),
            ("classicHome", "Classic/Buttons/Home")
        ]

        var result: [String: String] = [:]
        for (action, key) in targets {
            if let value = value(forKey: key, inSection: "Wiimote1", in: text) {
                result[action] = value
            }
        }
        return result
    }

    private func actionID(forToken token: String, values: [String: String]) -> String {
        values.first(where: { $0.value == token })?.key ?? "none"
    }

    private func classicActionID(forToken token: String, values: [String: String]) -> String {
        values.first(where: { $0.value == token })?.key ?? "none"
    }

    private func validateControllerMappingText(_ text: String) -> Bool {
        if selectedControllerProfile == "classic_tvc" {
            guard isClassicProfile(text) else { return false }
            let requiredMovementKeys = [
                "Classic/D-Pad/Up", "Classic/D-Pad/Down", "Classic/D-Pad/Left", "Classic/D-Pad/Right",
                "Classic/Left Stick/Up", "Classic/Left Stick/Down", "Classic/Left Stick/Left", "Classic/Left Stick/Right"
            ]
            return requiredMovementKeys.allSatisfy { value(forKey: $0, inSection: "Wiimote1", in: text) != nil }
        }

        guard (value(forKey: "Extension", inSection: "Wiimote1", in: text) ?? "").caseInsensitiveCompare("None") == ComparisonResult.orderedSame else {
            return false
        }
        return parseBool(value(forKey: "Options/Sideways Wiimote", inSection: "Wiimote1", in: text) ?? "false")
    }

    private func createControllerOriginalIfNeeded() throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: wiimoteConfigURL.path), !fm.fileExists(atPath: controllerOriginalURL.path) else {
            return
        }
        try fm.createDirectory(at: controllerOriginalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.copyItem(at: wiimoteConfigURL, to: controllerOriginalURL)
    }

    private func createControllerBackup(prefix: String) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: controllerBackupsURL, withIntermediateDirectories: true)
        let url = uniqueDirectory(in: controllerBackupsURL, baseName: "\(prefix)_\(Self.saveDateFormatter.string(from: Date())).ini")
        try fm.copyItem(at: wiimoteConfigURL, to: url)
    }

    // MARK: - Saves

    private static let saveDateFormatter: DateFormatter = {
        let f=DateFormatter(); f.locale=Locale(identifier:"en_US_POSIX"); f.dateFormat="yyyy-MM-dd_HH-mm-ss"; return f
    }()

    func loadSaveState() {
        saveFound = validateSaveFolder(activeSaveURL)
        saveStatusText = saveFound ? "Partida STKE08 detectada" : "No se encontró una partida válida"
        refreshSaveProfiles()
    }

    func createSaveBackup() {
        guard validateSaveFolder(activeSaveURL) else {
            presentError("No se encontró la partida", "Falta una partida válida de Tatsunoko vs. Capcom (STKE08) en UserData/Wii/title/00010000/53544b45.")
            return
        }
        do {
            let fm=FileManager.default; try fm.createDirectory(at: saveBackupsURL, withIntermediateDirectories: true)
            let name="Partida_\(Self.saveDateFormatter.string(from: Date()))"
            let dst=uniqueDirectory(in: saveBackupsURL, baseName: name)
            try fm.copyItem(at: activeSaveURL, to: dst)
            guard validateSaveFolder(dst) else { try? fm.removeItem(at: dst); throw NSError(domain:"TvCSettings",code:40,userInfo:[NSLocalizedDescriptionKey:"El respaldo copiado no superó la verificación."]) }
            refreshSaveProfiles(); selectedSaveProfileID = dst.path
            saveStatusText = "Respaldo creado: \(dst.lastPathComponent)"
        } catch { presentError("No se pudo crear el respaldo", error.localizedDescription) }
    }

    func importSaveProfile() {
        let panel=NSOpenPanel(); panel.canChooseDirectories=true; panel.canChooseFiles=false; panel.allowsMultipleSelection=false; panel.prompt="Importar"
        panel.message="Selecciona una carpeta de partida que contenga data/backup.bin, data/banner.bin y content/title.tmd."
        guard panel.runModal() == .OK, let source=panel.url else { return }
        guard validateSaveFolder(source) else {
            presentError("Partida no compatible", "La carpeta seleccionada no tiene la estructura esperada de STKE08: content/title.tmd, data/backup.bin y data/banner.bin.")
            return
        }
        do {
            let fm=FileManager.default; try fm.createDirectory(at: importedProfilesURL, withIntermediateDirectories: true)
            let base="Perfil_importado_\(Self.saveDateFormatter.string(from: Date()))"
            let dst=uniqueDirectory(in: importedProfilesURL, baseName: base)
            try fm.copyItem(at: source, to: dst)
            guard validateSaveFolder(dst) else { try? fm.removeItem(at: dst); throw NSError(domain:"TvCSettings",code:41,userInfo:[NSLocalizedDescriptionKey:"El perfil importado no superó la verificación."]) }
            refreshSaveProfiles(); selectedSaveProfileID=dst.path; saveStatusText="Perfil importado y listo para activar"
        } catch { presentError("No se pudo importar la partida", error.localizedDescription) }
    }

    func activateSelectedSaveProfile() {
        guard let profile=selectedSaveProfile else { presentError("Selecciona una partida", "Elige primero un perfil o respaldo en la lista."); return }
        guard validateSaveFolder(profile.url) else { presentError("Perfil no válido", "El perfil seleccionado ya no contiene una partida válida."); return }
        do {
            if validateSaveFolder(activeSaveURL) {
                let fm=FileManager.default; try fm.createDirectory(at: saveBackupsURL, withIntermediateDirectories: true)
                let auto=uniqueDirectory(in: saveBackupsURL, baseName:"Auto_antes_de_activar_\(Self.saveDateFormatter.string(from: Date()))")
                try fm.copyItem(at: activeSaveURL, to: auto)
                guard validateSaveFolder(auto) else { try? fm.removeItem(at:auto); throw NSError(domain:"TvCSettings",code:42,userInfo:[NSLocalizedDescriptionKey:"No se pudo verificar el respaldo automático. No se modificó la partida activa."]) }
            }
            let fm=FileManager.default
            let parent=activeSaveURL.deletingLastPathComponent(); try fm.createDirectory(at: parent, withIntermediateDirectories:true)
            let staging=parent.appendingPathComponent("53544b45.tvc-staging",isDirectory:true)
            let rollback=parent.appendingPathComponent("53544b45.tvc-rollback",isDirectory:true)
            try? fm.removeItem(at: staging); try? fm.removeItem(at: rollback)
            try fm.copyItem(at: profile.url, to: staging)
            guard validateSaveFolder(staging) else { try? fm.removeItem(at:staging); throw NSError(domain:"TvCSettings",code:43,userInfo:[NSLocalizedDescriptionKey:"La copia temporal no superó la verificación. No se modificó la partida activa."]) }
            if fm.fileExists(atPath: activeSaveURL.path) { try fm.moveItem(at: activeSaveURL, to: rollback) }
            do {
                try fm.moveItem(at: staging, to: activeSaveURL)
                guard validateSaveFolder(activeSaveURL) else { throw NSError(domain:"TvCSettings",code:44,userInfo:[NSLocalizedDescriptionKey:"La partida activada no superó la verificación final."]) }
                try? fm.removeItem(at: rollback)
            } catch {
                try? fm.removeItem(at: activeSaveURL)
                if fm.fileExists(atPath: rollback.path) { try? fm.moveItem(at: rollback, to: activeSaveURL) }
                throw error
            }
            loadSaveState(); saveStatusText="Partida activada correctamente"
        } catch { presentError("No se pudo activar la partida", error.localizedDescription) }
    }

    private func validateSaveFolder(_ url: URL) -> Bool {
        let fm=FileManager.default
        return fm.fileExists(atPath:url.appendingPathComponent("content/title.tmd").path) && fm.fileExists(atPath:url.appendingPathComponent("data/backup.bin").path) && fm.fileExists(atPath:url.appendingPathComponent("data/banner.bin").path)
    }

    private func refreshSaveProfiles() {
        var result:[SaveProfile]=[]
        func collect(from root:URL,isBackup:Bool) {
            guard let urls=try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys:nil, options:[.skipsHiddenFiles]) else { return }
            for url in urls where validateSaveFolder(url) {
                result.append(SaveProfile(id:url.path,title:url.lastPathComponent,detail:isBackup ? "Respaldo local" : "Perfil importado",url:url,isBackup:isBackup))
            }
        }
        collect(from:saveBackupsURL,isBackup:true); collect(from:importedProfilesURL,isBackup:false)
        saveProfiles=result.sorted{$0.title.localizedStandardCompare($1.title) == ComparisonResult.orderedDescending}
        if !saveProfiles.contains(where:{$0.id==selectedSaveProfileID}) { selectedSaveProfileID=saveProfiles.first?.id ?? "" }
    }

    private func uniqueDirectory(in root: URL, baseName: String) -> URL {
        var candidate=root.appendingPathComponent(baseName); var n=2
        while FileManager.default.fileExists(atPath:candidate.path) { candidate=root.appendingPathComponent("\(baseName)_\(n)"); n += 1 }
        return candidate
    }

    // MARK: - CRT/config helpers

    private func loadCRTState() {
        externalShaderName=""; selectedCRT="off"
        guard let text=try? String(contentsOf:gfxConfigURL,encoding:.utf8), let shader=value(forKey:"PostProcessingShader",inSection:"Enhancements",in:text) else { return }
        let s=shader.trimmingCharacters(in:.whitespacesAndNewlines)
        if s.isEmpty || s.caseInsensitiveCompare("(off)") == ComparisonResult.orderedSame { selectedCRT="off" }
        else if s.caseInsensitiveCompare("TvC_CRT_Adaptive_Soft") == ComparisonResult.orderedSame { selectedCRT="soft" }
        else if s.caseInsensitiveCompare("TvC_CRT_Adaptive_Strong") == ComparisonResult.orderedSame { selectedCRT="strong" }
        else { externalShaderName=s; selectedCRT="external" }
    }

    private func saveCRTConfiguration() throws {
        let fm=FileManager.default; try fm.createDirectory(at:gfxConfigURL.deletingLastPathComponent(),withIntermediateDirectories:true)
        if selectedCRT=="external" { return }
        var text=""
        if fm.fileExists(atPath:gfxConfigURL.path) { text=try String(contentsOf:gfxConfigURL,encoding:.utf8); try? fm.removeItem(at:gfxBackupURL); try fm.copyItem(at:gfxConfigURL,to:gfxBackupURL) }
        let shader=selectedCRTOption.shaderName ?? ""; if !shader.isEmpty { try installShader(named:shader) }
        text=replacingValue(forKey:"PostProcessingShader",with:shader,inSection:"Enhancements",in:text)
        try text.write(to:gfxConfigURL,atomically:true,encoding:.utf8)
    }

    private func installShader(named shaderName:String) throws {
        guard let root=Bundle.main.resourceURL else { throw NSError(domain:"TvCSettings",code:10,userInfo:[NSLocalizedDescriptionKey:"No se encontró la carpeta Resources de TvC Settings."]) }
        let src=root.appendingPathComponent("Shaders/\(shaderName).glsl")
        guard FileManager.default.fileExists(atPath:src.path) else { throw NSError(domain:"TvCSettings",code:11,userInfo:[NSLocalizedDescriptionKey:"Falta el shader incluido: \(shaderName).glsl"]) }
        try FileManager.default.createDirectory(at:shadersURL,withIntermediateDirectories:true)
        let dst=shadersURL.appendingPathComponent("\(shaderName).glsl"); try? FileManager.default.removeItem(at:dst); try FileManager.default.copyItem(at:src,to:dst)
    }

    private func parseBool(_ value:String)->Bool { ["1","true","yes","on"].contains(value.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()) }
    private func friendlyControllerName(_ raw:String)->String {
        let v=raw.trimmingCharacters(in:.whitespacesAndNewlines); guard !v.isEmpty else{return "Perfil existente"}
        let p=v.split(separator:"/",omittingEmptySubsequences:true); if p.count>=3 && p[0].caseInsensitiveCompare("SDL") == ComparisonResult.orderedSame { return p.dropFirst(2).joined(separator:"/") }; return v
    }
    private func readControllerProfile(from text:String)->String {
        if let c=value(forKey:"controller1",in:text),!c.isEmpty{return friendlyControllerName(c)}
        if let c=value(forKey:"controller",in:text),!c.isEmpty{return friendlyControllerName(c)}
        if let w=try? String(contentsOf:wiimoteConfigURL,encoding:.utf8),let d=value(forKey:"Device",inSection:"Wiimote1",in:w){return friendlyControllerName(d)}
        return "Perfil no detectado"
    }
    private func value(forKey key:String,in text:String)->String? {
        for raw in text.components(separatedBy:.newlines){let line=raw.trimmingCharacters(in:.whitespacesAndNewlines);guard !line.isEmpty,!line.hasPrefix("#"),!line.hasPrefix(";"),!line.hasPrefix("["),let sep=line.firstIndex(of:"=") else{continue};let k=String(line[..<sep]).trimmingCharacters(in:.whitespaces);if k.caseInsensitiveCompare(key) == ComparisonResult.orderedSame{return String(line[line.index(after:sep)...]).trimmingCharacters(in:.whitespaces)}};return nil
    }
    private func value(forKey key:String,inSection section:String,in text:String)->String? {
        var inside=false
        for raw in text.components(separatedBy:.newlines){let line=raw.trimmingCharacters(in:.whitespacesAndNewlines);if line.hasPrefix("[")&&line.hasSuffix("]"){inside=String(line.dropFirst().dropLast()).caseInsensitiveCompare(section) == ComparisonResult.orderedSame;continue};guard inside,!line.isEmpty,!line.hasPrefix("#"),!line.hasPrefix(";"),let sep=line.firstIndex(of:"=") else{continue};let k=String(line[..<sep]).trimmingCharacters(in:.whitespaces);if k.caseInsensitiveCompare(key) == ComparisonResult.orderedSame{return String(line[line.index(after:sep)...]).trimmingCharacters(in:.whitespaces)}};return nil
    }
    private func replacingValue(forKey key:String,with newValue:String,in text:String)->String {
        var lines=text.components(separatedBy:.newlines)
        for i in lines.indices{let t=lines[i].trimmingCharacters(in:.whitespacesAndNewlines);guard !t.hasPrefix("#"),!t.hasPrefix(";"),!t.hasPrefix("["),let sep=lines[i].firstIndex(of:"=") else{continue};let k=String(lines[i][..<sep]).trimmingCharacters(in:.whitespaces);if k.caseInsensitiveCompare(key) == ComparisonResult.orderedSame{lines[i]=String(lines[i][..<lines[i].index(after:sep)])+newValue;return lines.joined(separator:"\n")}}
        if let v=lines.firstIndex(where:{$0.trimmingCharacters(in:.whitespacesAndNewlines).caseInsensitiveCompare("[Video]") == ComparisonResult.orderedSame}){lines.insert("\(key)=\(newValue)",at:min(v+1,lines.count))}else{if !(lines.last?.isEmpty ?? true){lines.append("")};lines += ["[Video]","\(key)=\(newValue)"]};return lines.joined(separator:"\n")
    }
    private func replacingValue(forKey key:String,with newValue:String,inSection section:String,in text:String)->String {
        var lines=text.components(separatedBy:.newlines);var start:Int?;var end=lines.count
        for i in lines.indices{let t=lines[i].trimmingCharacters(in:.whitespacesAndNewlines);if t.hasPrefix("[")&&t.hasSuffix("]"){let s=String(t.dropFirst().dropLast());if start==nil&&s.caseInsensitiveCompare(section) == ComparisonResult.orderedSame{start=i;continue};if start != nil{end=i;break}}}
        if let s=start{if s+1<end{for i in (s+1)..<end{let l=lines[i];guard let sep=l.firstIndex(of:"=") else{continue};let k=String(l[..<sep]).trimmingCharacters(in:.whitespaces);if k.caseInsensitiveCompare(key) == ComparisonResult.orderedSame{lines[i]="\(key) = \(newValue)";return lines.joined(separator:"\n")}}};lines.insert("\(key) = \(newValue)",at:end);return lines.joined(separator:"\n")}
        if !(lines.last?.isEmpty ?? true){lines.append("")};lines += ["[\(section)]","\(key) = \(newValue)"];return lines.joined(separator:"\n")
    }
    private func presentError(_ title:String,_ message:String){alertTitle=title;alertMessage=message;showAlert=true}
}

struct StatusPill: View {
    let label:String; let good:Bool
    var body:some View{HStack(spacing:7){Circle().fill(good ? Color.green:Color.orange).frame(width:8,height:8);Text(label).font(.system(size:12,weight:.medium)).foregroundStyle(.secondary)}.padding(.horizontal,11).padding(.vertical,7).background(.white.opacity(0.055),in:Capsule())}
}

struct InfoRow:View{
    let title:String;let value:String;let symbol:String
    var body:some View{HStack(spacing:12){Image(systemName:symbol).font(.system(size:16,weight:.semibold)).foregroundStyle(Color.red.opacity(0.92)).frame(width:24);VStack(alignment:.leading,spacing:2){Text(title).font(.system(size:12,weight:.medium)).foregroundStyle(.secondary);Text(value).font(.system(size:14,weight:.semibold)).lineLimit(1).truncationMode(.middle)};Spacer(minLength:0)}}
}

struct BundleResourceImage: View {
    let name:String
    var body:some View {
        Group {
            if let url=Bundle.main.url(forResource:name,withExtension:"png"),let image=NSImage(contentsOf:url){Image(nsImage:image).resizable().scaledToFit()}
            else { VStack{Image(systemName:"gamecontroller").font(.system(size:42));Text("Referencia del mando no disponible").font(.caption).foregroundStyle(.secondary)} }
        }
    }
}

struct XboxButtonGlyph: View {
    let id: String
    let title: String

    private var faceColor: Color {
        switch id {
        case "A": return .green
        case "B": return .red
        case "X": return .blue
        case "Y": return .yellow
        default: return .white.opacity(0.14)
        }
    }

    var body: some View {
        Group {
            if ["A", "B", "X", "Y"].contains(id) {
                ZStack {
                    Circle().fill(faceColor.opacity(0.90))
                    Text(title).font(.system(size:12, weight: .black, design: .rounded)).foregroundStyle(id == "Y" ? Color.black : Color.white)
                }
                .frame(width: 30, height: 30)
            } else if id == "View" {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size:13, weight:.bold))
                    .frame(width:42, height:26)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius:7))
            } else if id == "Menu" {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size:13, weight:.bold))
                    .frame(width:42, height:26)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius:7))
            } else if id == "Guide" {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size:13, weight:.bold))
                    .frame(width:42, height:26)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius:7))
            } else {
                Text(title)
                    .font(.system(size:11, weight:.bold, design:.rounded))
                    .frame(width:42, height:26)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius:7))
            }
        }
        .overlay(RoundedRectangle(cornerRadius:7).stroke(.white.opacity(0.08)))
        .accessibilityLabel(title)
    }
}

struct XboxButtonBadge: View {
    let text: String
    var body: some View { XboxButtonGlyph(id: text == "Xbox" ? "Guide" : text, title: text) }
}

struct ControllerActionGlyph: View {
    let actionID: String

    private var symbol: String {
        switch actionID {
        case "classicY", "wii1": return "1.circle.fill"
        case "classicX": return "2.circle.fill"
        case "classicA", "classicL": return "3.circle.fill"
        case "classicB", "partner": return "person.2.fill"
        case "classicR": return "burst.fill"
        case "wii2": return "bolt.fill"
        case "megacrash": return "burst.fill"
        case "classicMinus", "taunt": return "face.smiling"
        case "classicPlus", "pause": return "pause.fill"
        case "classicHome", "home": return "house.fill"
        default: return "minus"
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size:13, weight:.semibold))
            .foregroundStyle(actionID == "none" ? Color.secondary : Color.red.opacity(0.95))
            .frame(width:24, height:24)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius:6))
    }
}

struct ControllerLegendCard: View {
    let button: XboxButtonOption
    let actionID: String
    let actionTitle: String

    var body: some View {
        HStack(spacing:9) {
            XboxButtonGlyph(id: button.id, title: button.title)
            Image(systemName: "arrow.right")
                .font(.system(size:9, weight:.bold))
                .foregroundStyle(.secondary)
            ControllerActionGlyph(actionID: actionID)
            Text(actionTitle)
                .font(.system(size:10.5, weight:.semibold))
                .foregroundStyle(actionID == "none" ? .secondary : .primary)
                .lineLimit(2)
            Spacer(minLength:0)
        }
        .padding(.horizontal,10)
        .padding(.vertical,8)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius:10))
    }
}

struct ContentView:View{
    @StateObject private var manager=ConfigManager()
    @State private var selectedTab:MainTab = .general
    @State private var showStopConfirmation=false
    @State private var showForceStopConfirmation=false

    var body:some View{
        ZStack{LinearGradient(colors:[Color(red:0.075,green:0.075,blue:0.085),Color(red:0.035,green:0.035,blue:0.045)],startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea();VStack(spacing:0){header;Divider().opacity(0.35);mainContent;Divider().opacity(0.35);footer}}
            .frame(minWidth:1040,idealWidth:1100,minHeight:760,idealHeight:800)
            .preferredColorScheme(.dark)
            .onAppear{manager.load()}
            .alert(manager.alertTitle,isPresented:$manager.showAlert){Button("Aceptar",role:.cancel){}}message:{Text(manager.alertMessage)}
            .confirmationDialog("Cerrar Tatsunoko vs Capcom?",isPresented:$showStopConfirmation,titleVisibility:.visible){Button("Cerrar normalmente"){manager.stopGame(force:false)};Button("Cancelar",role:.cancel){}}message:{Text("El progreso no guardado dentro del juego podría perderse. Se solicitará primero un cierre normal a macOS.")}
            .confirmationDialog("¿Forzar cierre?",isPresented:$showForceStopConfirmation,titleVisibility:.visible){Button("FORZAR CIERRE",role:.destructive){manager.stopGame(force:true)};Button("Cancelar",role:.cancel){}}message:{Text("Úsalo solo si el juego no respondió al apagado normal. El progreso no guardado podría perderse.")}
    }

    private var header:some View{HStack(spacing:16){ZStack{RoundedRectangle(cornerRadius:14).fill(Color.red.opacity(0.16));Image(systemName:"gamecontroller.fill").font(.system(size:28,weight:.semibold)).foregroundStyle(Color.red)}.frame(width:58,height:58);VStack(alignment:.leading,spacing:4){Text("TATSUNOKO vs. CAPCOM").font(.system(size:22,weight:.bold,design:.rounded));Text("Ultimate All-Stars · ARM64 · Apple Silicon · Settings 0.6.3").font(.system(size:13,weight:.medium)).foregroundStyle(.secondary)};Spacer();StatusPill(label:manager.configFound ? "Portable listo":"UserData no encontrado",good:manager.configFound)}.padding(.horizontal,28).padding(.vertical,20)}

    private var mainContent:some View{VStack(spacing:0){tabBar;ScrollView{Group{switch selectedTab{case .general:generalSection;case .controller:controllerSection;case .saves:saveSection}}.padding(26).frame(maxWidth:.infinity,alignment:.topLeading)}}.frame(maxHeight:.infinity)}

    private var tabBar:some View{HStack(spacing:6){ForEach(MainTab.allCases){tab in Button{selectedTab=tab;if tab == .saves{manager.loadSaveState()};if tab == .controller{manager.loadControllerMapping()}}label:{HStack(spacing:8){Image(systemName:tab.symbol);Text(tab.rawValue).fontWeight(.semibold)}.padding(.horizontal,16).padding(.vertical,10).background(selectedTab==tab ? Color.red.opacity(0.18):Color.clear,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(selectedTab==tab ? Color.red.opacity(0.32):Color.clear))}.buttonStyle(.plain).foregroundStyle(selectedTab==tab ? Color.primary:Color.secondary)};Spacer()}.padding(.horizontal,26).padding(.vertical,12).background(.black.opacity(0.08))}

    private var generalSection:some View{
        HStack(alignment:.top,spacing:18){
            VStack(alignment:.leading,spacing:16){sectionLabel("VIDEO");VStack(alignment:.leading,spacing:14){labelPair("Resolución interna","Controla el EFB de Wii. No cambia la resolución física de tu monitor.");Picker("Resolución",selection:$manager.selectedResolution){ForEach(ConfigManager.resolutions){o in Text("\(o.title) — \(o.detail)").tag(o.id)}}.labelsHidden().pickerStyle(.menu).onChange(of:manager.selectedResolution){_ in manager.markChanged()};HStack{Text(manager.selectedOption.detail).font(.system(size:12,weight:.medium)).foregroundStyle(.secondary);Spacer();if manager.selectedResolution=="640x528"{Text("ORIGINAL").font(.system(size:10,weight:.bold)).foregroundStyle(.green)}};Divider().opacity(0.25);Toggle(isOn:$manager.fullscreen){labelPair("Pantalla completa","Inicia esta copia portable ocupando toda la pantalla.")}.toggleStyle(.switch).onChange(of:manager.fullscreen){_ in manager.markChanged()};Divider().opacity(0.25);labelPair("Simulación CRT","Scanlines alineadas a píxeles físicos, sin patrón irregular. No altera FPS ni timing.");Picker("CRT",selection:$manager.selectedCRT){ForEach(manager.crtOptions){o in Text("\(o.title) — \(o.detail)").tag(o.id)}}.labelsHidden().pickerStyle(.menu).onChange(of:manager.selectedCRT){_ in manager.markCRTChanged()};HStack{Image(systemName:"display").foregroundStyle(.secondary);Text(manager.selectedCRTOption.detail).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary);Spacer();if manager.hasUnsavedChanges{Text("Cambios sin guardar").font(.system(size:11,weight:.semibold)).foregroundStyle(.orange)}}}.card();Text("La opción Nativa Wii usa EFB 1×. El modo CRT usa una sola línea oscura por grupo de píxeles físicos para evitar aliasing y patrones 2+1 en 1080p/1440p/4K/5K.").footnoteStyle()}.frame(maxWidth:.infinity,alignment:.leading)
            VStack(alignment:.leading,spacing:14){sectionLabel("SISTEMA");VStack(spacing:12){InfoRow(title:"Backend de ejecución",value:"Metal · portable ARM64",symbol:"square.3.layers.3d");Divider().opacity(0.3);InfoRow(title:"Valor heredado config.ini",value:manager.backendConfigName,symbol:"doc.text");Divider().opacity(0.3);InfoRow(title:"Control físico",value:manager.controllerName,symbol:"gamecontroller");Divider().opacity(0.3);InfoRow(title:"Juego",value:manager.isGameRunning ? "Ejecutándose · esta copia portable":(manager.canLaunchGame ? "Detenido · esta copia portable":"No encontrado"),symbol:"power.circle.fill");Divider().opacity(0.3);InfoRow(title:"Configuración",value:manager.statusText,symbol:"gearshape.2")}.card();Text("JUGAR abre siempre Tatsunoko vs Capcom.app ubicado junto a este configurador. No usa rutas fijas ni otra copia del juego.").footnoteStyle();Text("Antes de guardar se respaldan config.ini y, cuando corresponde, GFX.ini. Los shaders CRT se instalan dentro de UserData/Shaders.").footnoteStyle()}.frame(width:360,alignment:.leading)
        }
    }

    private var controllerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    sectionLabel("CONTROL XBOX")
                    Text("Configuración del mando físico para Tatsunoko vs. Capcom")
                        .font(.system(size:14, weight:.semibold))
                }
                Spacer()
                StatusPill(label: manager.controllerStatusText, good: manager.controllerConfigFound)
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Referencia visual del mando")
                        .font(.system(size:14, weight:.semibold))

                    BundleResourceImage(name: "xbox_lineart")
                        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 300)
                        .padding(12)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius:16))

                    HStack {
                        Text("INFOGRAFÍA ACTIVA")
                            .font(.system(size:10, weight:.bold))
                            .foregroundStyle(.secondary)
                            .tracking(1.0)
                        Spacer()
                        Text(manager.selectedControllerProfile == "classic_tvc" ? "Classic Controller · TvC" : "Wiimote horizontal")
                            .font(.system(size:10, weight:.semibold))
                            .foregroundStyle(.red)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(ConfigManager.xboxButtons) { button in
                            ControllerLegendCard(
                                button: button,
                                actionID: manager.activeActionID(forButton: button.id),
                                actionTitle: manager.activeActionTitle(forButton: button.id)
                            )
                        }
                    }

                    HStack(spacing:10) {
                        Image(systemName: "dpad.fill")
                            .font(.system(size:18, weight:.semibold))
                            .foregroundStyle(.red)
                            .frame(width:30)
                        VStack(alignment:.leading, spacing:2) {
                            Text("D-Pad + Stick izquierdo")
                                .font(.system(size:11, weight:.semibold))
                            Text("Movimiento y selección · asignación fija")
                                .font(.system(size:10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(.red.opacity(0.06), in: RoundedRectangle(cornerRadius:10))

                    Text("Los pictogramas muestran la función real de cada botón en el perfil activo. Cambian inmediatamente al remapear.")
                        .footnoteStyle()
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Perfil de mando")
                        .font(.system(size:14, weight:.semibold))

                    Picker("Perfil", selection: $manager.selectedControllerProfile) {
                        Text("Classic Controller · TvC — recomendado").tag("classic_tvc")
                        Text("Wiimote horizontal · personalizable").tag("legacy_custom")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: manager.selectedControllerProfile) { value in
                        manager.setControllerProfile(value)
                    }

                    if manager.selectedControllerProfile == "classic_tvc" {
                        Text("Perfil validado en el juego. Ahora también puede remapearse sin perder la emulación Classic Controller.")
                            .footnoteStyle()

                        HStack {
                            Text("Remapeo Classic Controller")
                                .font(.system(size:13, weight:.semibold))
                            Spacer()
                            Button("Restaurar recomendado") {
                                manager.restoreRecommendedClassicMapping()
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size:10, weight:.semibold))
                        }

                        ForEach(ConfigManager.xboxButtons) { button in
                            HStack(spacing:10) {
                                XboxButtonGlyph(id: button.id, title: button.title)
                                ControllerActionGlyph(actionID: manager.classicControllerBindings[button.id] ?? "none")
                                Picker(button.title, selection: Binding(
                                    get: { manager.classicControllerBindings[button.id] ?? "none" },
                                    set: { manager.setClassicControllerBinding(buttonID: button.id, actionID: $0) }
                                )) {
                                    ForEach(ConfigManager.classicControllerActions) { action in
                                        Text("\(action.title) — \(action.detail)").tag(action.id)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                            }
                        }

                        Text("Classic A/B/X/Y/L/R, −, + y HOME son remapeables. D-Pad y stick izquierdo se mantienen dedicados al movimiento.")
                            .footnoteStyle()
                    } else {
                        Text("Mapeo de botones")
                            .font(.system(size:13, weight:.semibold))

                        ForEach(ConfigManager.xboxButtons) { button in
                            HStack(spacing:10) {
                                XboxButtonGlyph(id: button.id, title: button.title)
                                ControllerActionGlyph(actionID: manager.controllerBindings[button.id] ?? "none")
                                Picker(button.title, selection: Binding(
                                    get: { manager.controllerBindings[button.id] ?? "none" },
                                    set: { manager.setControllerBinding(buttonID: button.id, actionID: $0) }
                                )) {
                                    ForEach(ConfigManager.controllerActions) { action in
                                        Text(action.detail).tag(action.id)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                            }
                        }

                        Text("Asignación fija: D-Pad / Stick izquierdo → movimiento.")
                            .footnoteStyle()
                    }

                    Divider().opacity(0.25)

                    HStack {
                        Button("Restaurar original") {
                            manager.restoreControllerOriginal()
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Guardar mapeo") {
                            manager.saveControllerMapping()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(!manager.controllerHasUnsavedChanges)
                    }
                }
                .padding(16)
                .frame(width:470, alignment:.leading)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius:16))
            }
        }
    }

    private var saveSection:some View{
        VStack(alignment:.leading,spacing:16){HStack{VStack(alignment:.leading,spacing:3){sectionLabel("PARTIDAS GUARDADAS");Text("Gestor seguro de perfiles STKE08").font(.system(size:14,weight:.semibold))};Spacer();StatusPill(label:manager.saveFound ? "Partida detectada":"Partida no encontrada",good:manager.saveFound)}
            HStack(alignment:.top,spacing:18){VStack(alignment:.leading,spacing:14){HStack(spacing:10){Image(systemName:"shield.checkered").foregroundStyle(.green);Text("Antes de activar cualquier perfil, TvC Settings crea y verifica un respaldo automático de la partida activa. El reemplazo usa una copia temporal y rollback; no modifica Tatsunoko vs Capcom.app ni el ejecutable ARM64.").font(.system(size:12,weight:.medium)).foregroundStyle(.secondary)}.padding(14).background(.green.opacity(0.06),in:RoundedRectangle(cornerRadius:14));labelPair("Partida activa",manager.saveStatusText);Text("UserData/Wii/title/00010000/53544b45").font(.system(size:11,design:.monospaced)).foregroundStyle(.secondary);HStack{Button("Respaldar partida actual"){manager.createSaveBackup()}.buttonStyle(.borderedProminent).tint(.red).disabled(!manager.saveFound);Button("Importar perfil"){manager.importSaveProfile()}.buttonStyle(.bordered)}}.card().frame(maxWidth:.infinity)
                VStack(alignment:.leading,spacing:12){Text("Perfil para activar").font(.system(size:14,weight:.semibold));if manager.saveProfiles.isEmpty{Text("No hay perfiles ni respaldos todavía.").font(.system(size:12)).foregroundStyle(.secondary)}else{Picker("Perfil",selection:$manager.selectedSaveProfileID){ForEach(manager.saveProfiles){p in Text("\(p.title) — \(p.detail)").tag(p.id)}}.labelsHidden().pickerStyle(.menu);if let p=manager.selectedSaveProfile{Text(p.url.path).font(.system(size:10,design:.monospaced)).foregroundStyle(.secondary).lineLimit(3).truncationMode(.middle)};Button("Activar perfil seleccionado"){manager.activateSelectedSaveProfile()}.buttonStyle(.borderedProminent).tint(.red).disabled(manager.selectedSaveProfileID.isEmpty)}}.card().frame(width:430,alignment:.leading)
            }
        }
    }

    private var footer:some View{HStack(spacing:12){Button("Restaurar recomendado"){manager.restoreRecommended()}.buttonStyle(.borderless).foregroundStyle(.secondary);Spacer();if manager.isGameRunning{Button("CERRAR JUEGO"){showStopConfirmation=true}.buttonStyle(.bordered);if manager.forceQuitSuggested{Button("FORZAR CIERRE"){showForceStopConfirmation=true}.buttonStyle(.borderedProminent).tint(.orange)}};Button("Guardar cambios"){_ = manager.save()}.buttonStyle(.bordered).disabled(!manager.configFound || !manager.hasUnsavedChanges);Button{manager.launchGame()}label:{HStack(spacing:8){Image(systemName:"play.fill");Text("JUGAR").fontWeight(.bold)}.frame(minWidth:96)}.buttonStyle(.borderedProminent).tint(.red).disabled(!manager.canLaunchGame)}.padding(.horizontal,28).padding(.vertical,16).onAppear{manager.refreshGameRunningState()}}

    private func sectionLabel(_ text:String)->some View{Text(text).font(.system(size:11,weight:.bold)).foregroundStyle(.secondary).tracking(1.2)}
    private func labelPair(_ title:String,_ detail:String)->some View{VStack(alignment:.leading,spacing:3){Text(title).font(.system(size:14,weight:.semibold));Text(detail).font(.system(size:11)).foregroundStyle(.secondary)}}
}

private extension View {
    func card() -> some View { self.padding(16).background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:16)) }
    func footnoteStyle() -> some View { self.font(.system(size:11,weight:.medium)).foregroundStyle(.secondary.opacity(0.86)).fixedSize(horizontal:false,vertical:true) }
}

@main
struct TvCSettingsApp:App{
    var body:some Scene{WindowGroup("TvC Settings"){ContentView()}.windowResizability(.contentSize).defaultSize(width:1100,height:800).commands{CommandGroup(replacing:.newItem){}}}
}

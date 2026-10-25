//
//  BatteryAlertView.swift
//  AirBattery
//
//  Created by apple on 2024/10/18.
//

import SwiftUI

struct btAlert: Codable, Equatable {
    let name: String
    let full: Int
    let fullOn: Bool
    let fullSound: Bool
    let low: Int
    let lowOn: Bool
    let lowSound: Bool
    // 充电里程碑 (如 80/90/100%), 每次充电到达时只提醒一次; 可选字段以兼容旧数据
    var steps: [Int]? = nil
    var stepSound: Bool? = nil
}

let chargeMilestones = [80, 90, 100]

struct AlertInputView: View {
    @State private var name: String
    @State private var full: Int
    @State private var low: Int
    @State private var fullOn: Bool
    @State private var lowOn: Bool
    @State private var fullSound: Bool
    @State private var lowSound: Bool
    @State private var steps: [Int]
    @State private var stepSound: Bool
    @State private var overCloseButton = false
    @State private var alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []

    var iconName: String
    var onConfirm: (btAlert) -> Void
    var onCancel: () -> Void

    init(alert: btAlert, iconName: String, onConfirm: @escaping (btAlert) -> Void, onCancel: @escaping () -> Void) {
        _name = State(initialValue: alert.name)
        _full = State(initialValue: alert.full)
        _low = State(initialValue: alert.low)
        _fullOn = State(initialValue: alert.fullOn)
        _lowOn = State(initialValue: alert.lowOn)
        _fullSound = State(initialValue: alert.fullSound)
        _lowSound = State(initialValue: alert.lowSound)
        _steps = State(initialValue: alert.steps ?? [])
        _stepSound = State(initialValue: alert.stepSound ?? true)
        self.iconName = iconName
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            /*Color.clear
                .background(BlurView(material: .menu))
                .cornerRadius(14)*/
            VStack {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .padding()
                Text("Battery alert for")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                VStack {
                    HStack(spacing: 4) {
                        Text("Notify once when charging reaches:")
                            .foregroundColor(steps.isEmpty ? .secondary : .primary)
                        Spacer()
                        Button(action: {
                            stepSound.toggle()
                        }, label: {
                            Image(systemName: stepSound ? "speaker.wave.2.fill" :"speaker.slash.fill")
                                .foregroundColor(stepSound ? .primary : .secondary)
                        })
                        .frame(width: 20)
                        .buttonStyle(.plain)
                        .disabled(steps.isEmpty)
                    }
                    HStack(spacing: 8) {
                        ForEach(chargeMilestones, id: \.self) { step in
                            MilestoneChip(value: step, isOn: steps.contains(step)) {
                                if steps.contains(step) { steps.removeAll { $0 == step } } else { steps.append(step) }
                            }
                        }
                    }
                    Spacer().frame(height: 14)
                    HStack(spacing: 4) {
                        Toggle("Notify me when battery charged above:", isOn: $fullOn)
                            .toggleStyle(.checkbox)
                            .foregroundColor(fullOn ? .primary : .secondary)
                        Spacer()
                        Text("\(Int(full))%")
                            .fontWeight(.semibold)
                            .foregroundColor(fullOn ? getPowerColor(full) : .secondary)
                        Button(action: {
                            fullSound.toggle()
                        }, label: {
                            Image(systemName: fullSound ? "speaker.wave.2.fill" :"speaker.slash.fill")
                                .foregroundColor(fullSound ? .primary : .secondary)
                        })
                        .frame(width: 20)
                        .buttonStyle(.plain)
                        .disabled(!fullOn)
                    }
                    Slider(value: Binding(get: { Double(full) },
                                          set: { newValue in
                        if Int(newValue) <= low && low != 2 && lowOn {
                            full = low
                            return
                        }
                        let base: Int = Int(newValue.rounded())
                        let modulo: Int = base % 1
                        full = base - modulo
                    }), in: 1...99).disabled(!fullOn)
                    Spacer().frame(height: 14)
                    HStack(spacing: 4) {
                        Toggle("Notify me when battery goes below:", isOn: $lowOn)
                            .toggleStyle(.checkbox)
                            .foregroundColor(lowOn ? .primary : .secondary)
                        Spacer()
                        Text("\(Int(low))%")
                            .fontWeight(.semibold)
                            .foregroundColor(lowOn ? getPowerColor(low) : .secondary)
                        Button(action: {
                            lowSound.toggle()
                        }, label: {
                            Image(systemName: lowSound ? "speaker.wave.2.fill" :"speaker.slash.fill")
                                .foregroundColor(lowSound ? .primary : .secondary)
                        })
                        .frame(width: 20)
                        .buttonStyle(.plain)
                        .disabled(!lowOn)
                    }
                    Slider(value: Binding(get: { Double(low) },
                                          set: { newValue in
                        if Int(newValue) >= full && full != 99 && fullOn {
                            low = full
                            return
                        }
                        let base: Int = Int(newValue.rounded())
                        let modulo: Int = base % 1
                        low = base - modulo
                    }), in: 2...100).disabled(!lowOn)
                }
                .padding([.leading, .trailing], 5)
                .padding([.top, .bottom], 10)
                HStack(spacing: 16) {
                    let canDelete = alertList.map({$0.name}).contains(name)
                    if canDelete {
                        Button(action: {
                            alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
                            alertList.removeAll(where: {$0.name == name})
                            ud.set(object: alertList, forKey: "alertList")
                            onCancel()
                        }, label: {
                            Text("Delete")
                                .foregroundColor(.red)
                                .frame(width: 135, height: 30)
                        })
                    }
                    Button(action: {
                        let alert = btAlert(name: name, full: full, fullOn: fullOn, fullSound: fullSound, low: low, lowOn: lowOn, lowSound: lowSound,
                                            steps: steps.sorted(), stepSound: stepSound)
                        onConfirm(alert)
                    }, label: {
                        Text("Save").frame(width: canDelete ? 135 : 302, height: 30)
                    }).keyboardShortcut(.defaultAction)
                }.padding([.top, .bottom], 4)
            }.padding()
            Button(action: {
                onCancel()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(overCloseButton ? .blue : .secondary.opacity(0.5))
            })
            .padding(6)
            .buttonStyle(.plain)
            .onHover { newValue in overCloseButton = newValue }
        }
        .frame(width: 360)
        .background(BlurView(material: .menu).ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    func getPowerColor(_ level: Int) -> Color {
        var color = Color.green
        if level <= 10 {
            color = Color.red
        } else if level <= 20 {
            color = Color.myYellow
        }
        return color
    }
}

struct MilestoneChip: View {
    let value: Int
    let isOn: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isOn { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)) }
                Text("\(value)%").font(.system(size: 13, weight: .semibold).monospacedDigit())
            }
            .foregroundColor(isOn ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isOn ? Color.accentColor : Color.primary.opacity(hovering ? 0.14 : 0.08))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .onHover { hovering = $0 }
        .accessibilityLabel(Text("\(value)%"))
        .accessibilityValue(Text(isOn ? "On" : "Off"))
    }
}

class AlertWindowController {
    var window: NNSWindow?

    func showAlert(with alert: btAlert, iconName: String, onConfirm: @escaping (btAlert) -> Void, onCancel: @escaping () -> Void) {
        // 创建 AlertInputView，传入可选的 btAlert 对象
        let alertView = AlertInputView(alert: alert, iconName: iconName, onConfirm: { newAlert in
            // 确认操作后，关闭窗口并返回数据
            self.window?.close()
            onConfirm(newAlert)
        }, onCancel: {
            // 取消操作，关闭窗口
            self.window?.close()
            onCancel()
        })

        // 创建窗口
        let window = NNSWindow(contentViewController: NSHostingController(rootView: alertView))
        window.setContentSize(NSSize(width: 360, height: window.contentViewController?.view.fittingSize.height ?? 334))
        window.title = "Create Battery Alert"
        window.styleMask = [.fullSizeContentView]
        window.isOpaque = false
        window.level = .floating
        window.isRestorable = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.center()

        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // 保存窗口引用，避免窗口被销毁
        self.window = window
    }
}

func batteryAlert() {
    @AppStorage("nearCast") var nearCast = false
    
    let now = Date()
    lowPowerNoteDelay = lowPowerNoteDelay.filter { $0.value >= now.timeIntervalSince1970 }
    
    let alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
    var allDevices = AirBatteryModel.getAll()
    allDevices.append(ib2ab(InternalBattery.status))
    let ncFiles = getFiles(withExtension: "json", in: ncFolder)
    for ncFile in ncFiles { allDevices += AirBatteryModel.ncGetAll(url: ncFile) }
    
    for device in allDevices.filter({ alertList.map({$0.name}).contains($0.deviceName) }) {
        if let alert = alertList.first(where: { $0.name == device.deviceName }) {
            if device.batteryLevel < alert.low && device.isCharging == 0 && alert.lowOn {
                if let delay = lowPowerNoteDelay[device.deviceName], delay > now.timeIntervalSince1970 { continue }
                let title = "Low Battery".local
                let body = String(format: "\"%@\" remaining battery %d%%".local, device.deviceName, device.batteryLevel)
                createNotification(title: title, message: body, alertSound: alert.lowSound, delay: true, info: device.deviceName)
                if nearCast {
                    if let info = netcastService.createInfo(title: title, info: body) { netcastService.sendMessage(info) }
                }
            }
            if device.batteryLevel > alert.full && device.isCharging != 0 && alert.fullOn {
                if let delay = lowPowerNoteDelay[device.deviceName], delay > now.timeIntervalSince1970 { continue }
                let title = "Fully Charged".local
                let body = String(format: "\"%@\" battery has reached %d%%".local, device.deviceName, device.batteryLevel)
                createNotification(title: title, message: body, alertSound: alert.fullSound, delay: true, info: device.deviceName)
                if nearCast {
                    if let info = netcastService.createInfo(title: title, info: body) { netcastService.sendMessage(info) }
                }
            }
        }
    }
}

private var lastSeenLevel = [String: Int]()
private var reachedMilestones = [String: Set<Int>]()

func chargeMilestoneCheck() {
    @AppStorage("nearCast") var nearCast = false

    let watched = (ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []).filter { !($0.steps ?? []).isEmpty }
    if watched.isEmpty { return }

    var allDevices = AirBatteryModel.getAll()
    let ibStatus = InternalBattery.status
    if ibStatus.hasBattery { allDevices.append(ib2ab(ibStatus)) }
    let ncFiles = getFiles(withExtension: "json", in: ncFolder)
    for ncFile in ncFiles { allDevices += AirBatteryModel.ncGetAll(url: ncFile) }

    for alert in watched {
        guard let device = allDevices.first(where: { $0.deviceName == alert.name }), device.hasBattery else { continue }
        let level = device.batteryLevel
        let steps = alert.steps ?? []
        // 电量回落到阈值 3% 以下时重置, 下次充电可再次提醒 (留余量防止电量抖动重复提醒)
        var reached = (reachedMilestones[alert.name] ?? []).filter { level > $0 - 3 }
        defer {
            lastSeenLevel[alert.name] = level
            reachedMilestones[alert.name] = reached
        }
        guard let last = lastSeenLevel[alert.name] else {
            // 首次读取到该设备: 已超过的阈值视为已提醒, 避免启动时误报
            reached.formUnion(steps.filter { level >= $0 })
            continue
        }
        let charging = device.isCharging != 0 || device.isCharged || device.acPowered
        guard level > last, charging || level >= 100 else { continue }

        let newSteps = steps.filter { level >= $0 && !reached.contains($0) }
        // 一次跨越多个阈值时只提醒最高的那个
        guard let top = newSteps.max() else { continue }
        reached.formUnion(newSteps)

        let title = top >= 100 ? "Fully Charged".local : String(format: "%d%% Charged".local, top)
        let body = String(format: "\"%@\" battery has reached %d%%".local, device.deviceName, level)
        createNotification(title: title, message: body, alertSound: alert.stepSound ?? true, info: device.deviceName)
        if nearCast {
            if let info = netcastService.createInfo(title: title, info: body) { netcastService.sendMessage(info) }
        }
    }
}

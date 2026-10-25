//
//  ContentView.swift
//  AirBattery
//
//  Created by apple on 2023/9/4.
//
import AppKit
import SwiftUI
import WidgetKit
import Combine
//import UserNotifications

/*let test_data: [CGFloat] = [99,80,80,73,70,60,59,51,30,30,25,25,19,18,17,15,12,10,10,9] // 示例数据
struct BarChartView: View {
    let data: [CGFloat] // 电量数据，取值范围 0 到 1
    let barSpacing: CGFloat // 柱子之间的间距
    let barWidth: CGFloat // 柱子宽度

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: barSpacing) { // 设置底部对齐
                ForEach(0..<data.count, id: \.self) { index in
                    let height = (data[index] * geometry.size.height)/100
                    Capsule()
                        .fill(Color(getPowerColor(Int(data[index]))))
                        .frame(width: barWidth, height: height)
                        .padding(.bottom, -barWidth / 2) // 设置底部平坦
                }
            }
        }
    }
}*/

class AppearanceMonitor: ObservableObject {
    @Published var isDarkMode: Bool = false
    private var appearanceChangeCancellable: AnyCancellable?

    init() {
        updateAppearance()
        appearanceChangeCancellable = NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateAppearance()
            }
    }
    private func updateAppearance() {
        let appearance = NSApp.effectiveAppearance
        isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

struct MultiBatteryView: View {
    @AppStorage("showThisMac") var showThisMac = "icon"
    @AppStorage("carouselMode") var carouselMode = true
    @AppStorage("appearance") var appearance = "auto"
    @AppStorage("showOn") var showOn = "sbar"
    @AppStorage("widgetInterval") var widgetInterval = 0
    @AppStorage("readBTHID") var readBTHID = true
    @AppStorage("deviceName") var deviceName = "Mac"
    @AppStorage("nearCast") var nearCast = false
    @AppStorage("ncGroupID") var ncGroupID = ""
    
    @StateObject private var appearanceMonitor = AppearanceMonitor()

    @State private var rollCount = 1
    @State private var darkMode = getDarkMode()
    @State private var lastTime = Double(Date().timeIntervalSince1970)
    @State private var batteryList = AirBatteryModel.getAll()
    @State private var lineWidth = 6.0
    
    var body: some View {
        ZStack {
            Group{
                Image(darkMode ? "background_dark" : "background")
                RoundedRectangle(cornerRadius: 23.5, style: RoundedCornerStyle.continuous)
                    .strokeBorder(darkMode ? .white : .black, lineWidth: 2)
                    .frame(width: 104, height: 104)
                    .opacity(darkMode ? 0.25 : 0.0)
                RoundedRectangle(cornerRadius: 23.5, style: RoundedCornerStyle.continuous)
                    .strokeBorder(.black, lineWidth: 1)
                    .frame(width: 104, height: 104)
                    .opacity(darkMode ? 0.55 : 0.2)
            }
            if batteryList.count < 4 {
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth*1.2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(darkMode ? .white : .black)
                    .opacity(darkMode ? 0.2 : 0.13)
                    .rotationEffect(Angle(degrees: 135))
                    .offset(x:-24, y: -24)
                    .frame(width: 38, height: 38, alignment: .center)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(batteryList[0..<2], id: \.self) { item in
                            ZStack {
                                Group {
                                    Group {
                                        Circle()
                                            .trim(from: 0.0, to: 0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth*1.2, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(darkMode ? .white : .black)
                                            .opacity(darkMode ? 0.2 : 0.13)
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape(
                                                Circle()
                                                    .trim(from: 0.0, to: 0.75)
                                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            )
                                            .opacity(item.batteryLevel == 100 ? 0 : 1)
                                        Circle()
                                            .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                    }.rotationEffect(Angle(degrees: 135))
                                    
                                    if item.deviceType.contains("mac") && showThisMac == "percent"{
                                        Text(String(item.batteryLevel))
                                            .colorScheme(darkMode ? .dark : .light)
                                            .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item)) : .blackWhite)
                                            .font(.custom("Helvetica-Bold", size: item.batteryLevel>99 ? 32 : 42))
                                            .frame(width: 100, alignment: .center)
                                            .scaleEffect(0.5)
                                            .offset(x:-0.2, y:1.5)
                                        
                                    } else {
                                        Image(getDeviceIcon(item))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .colorScheme(darkMode ? .dark : .light)
                                            .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item)) : .blackWhite)
                                            .offset(y:-1)
                                            .frame(width: 44, height: 43, alignment: .center)
                                            .scaleEffect(0.5)
                                    }
                                }.frame(width: 38, height: 38, alignment: .center)
                                Text(item.hasBattery ? "\(item.batteryLevel)" : "")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(darkMode ? .white : .black)
                                    .scaleEffect(0.5)
                                    .offset(y: 17)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach(batteryList[2..<4], id: \.self) { item in
                            ZStack {
                                Group {
                                    Group {
                                        Circle()
                                            .trim(from: 0.0, to: 0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth*1.2, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(darkMode ? .white : .black)
                                            .opacity(darkMode ? 0.2 : 0.13)
                                        Circle()
                                            .trim(from: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.001)), to: CGFloat(abs((min(Double(item.batteryLevel)/100.0*0.75, 0.75))-0.0005)))
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                            .shadow(color: .black, radius: lineWidth*0.76, x: 0, y: 0)
                                            .clipShape(
                                                Circle()
                                                    .trim(from: 0.0, to: 0.75)
                                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            )
                                            .opacity(item.batteryLevel == 100 ? 0 : 1)
                                        Circle()
                                            .trim(from: 0.0, to: Double(item.batteryLevel)/100.0*0.75)
                                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(Color(getPowerColor(item)))
                                    }.rotationEffect(Angle(degrees: 135))
                                    Image(getDeviceIcon(item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .colorScheme(darkMode ? .dark : .light)
                                        .foregroundColor(item.isCharging != 0 ? Color("dark_"+getPowerColor(item)) : .blackWhite)
                                        .offset(y:-1)
                                        .frame(width: 44, height: 43, alignment: .center)
                                        .scaleEffect(0.5)
                                }.frame(width: 38, height: 38, alignment: .center)
                                Text(item.hasBattery ? "\(item.batteryLevel)" : "")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(darkMode ? .white : .black)
                                    .scaleEffect(0.5)
                                    .offset(y: 17)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 128, height: 128, alignment: .center)
        .onChange(of: appearanceMonitor.isDarkMode) { newValue in
            darkMode = newValue
            NSApp.dockTile.display()
        }
        .onChange(of: appearance) { _ in
            darkMode = getDarkMode()
            NSApp.dockTile.display()
        }
        .onReceive(alertTimer) {_ in batteryAlert() }
        .onReceive(milestoneTimer) {_ in chargeMilestoneCheck() }
        .onReceive(widgetViewTimer) {_ in
            if widgetInterval != -1 { WidgetCenter.shared.reloadAllTimelines() }
        }
        .onReceive(dockTimer) {_ in IDeviceBattery.shared.scanDevices() }
        .onReceive(widgetDataTimer) {_ in
            SPBluetoothDataModel.shared.refeshData (completion: { result in
                DispatchQueue.global(qos: .background).async {
                    MagicBattery.shared.scanDevices()
                    AirBatteryModel.writeData()
                }
            }, error: {
                AirBatteryModel.writeData()
            })
        }
        .onReceive(nearCastTimer) {_ in
            if nearCast && ncGroupID != ""{
                var allDevices = AirBatteryModel.getAll()
                allDevices.insert(ib2ab(InternalBattery.status), at: 0)
                do {
                    let jsonData = try JSONEncoder().encode(allDevices)
                    guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
                    guard let data = encryptString(jsonString, password: ncGroupID) else { return }
                    let message = NCMessage(id: String(ncGroupID.prefix(15)), sender: systemUUID ?? deviceName, command: "", content: data)
                    netcastService.sendMessage(message)
                } catch {
                    print("Write JSON error：\(error)")
                }
            }
        }
        .onReceive(dockTimer) { t in
            if showOn == "both" || showOn == "dock" {
                var list = AirBatteryModel.getAll()
                let ncFiles = getFiles(withExtension: "json", in: ncFolder)
                for ncFile in ncFiles { list += AirBatteryModel.ncGetAll(url: ncFile) }
                let ibStatus = InternalBattery.status
                let now = Double(t.timeIntervalSince1970)
                
                if !carouselMode { rollCount = 1 }
                if ibStatus.hasBattery && showThisMac != "hidden" { list.insert(ib2ab(ibStatus), at: 0) }
                
                batteryList = sliceList(data: list, length: 4, count: rollCount)
                if batteryList == []{
                    rollCount = 1
                    batteryList = sliceList(data: list, length: 4, count: rollCount)
                }
                
                if now - lastTime >= 20 && list.count > 4 && carouselMode {
                    lastTime = now
                    rollCount = rollCount + 1
                }
                NSApp.dockTile.display()
            }
        }
    }
}

struct BlurView: NSViewRepresentable {
    
    private let material: NSVisualEffectView.Material
    
    init(material: NSVisualEffectView.Material) {
        self.material = material
    }
    
    func makeNSView(context: Context) -> some NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.material = material
    }
}

// MARK: - Popover

let popoverWidth: CGFloat = 352

private struct PopoverHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

extension Device {
    // 用于 ForEach 的稳定标识, 电量变化时不会导致行视图被重建 (保持悬停状态)
    var rowID: String { "\(deviceID)|\(deviceName)" }
    var isInternal: Bool { deviceID == "@MacInternalBattery" }
}

struct popover: View {
    var fromDock: Bool = false
    var allDevice: [Device]

    @AppStorage("nearCast") var nearCast = false

    @State private var allDevices = [Device]()
    @State private var hiddenDevices = AirBatteryModel.getBlackList()
    @State private var alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
    @State private var pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
    @State private var allNearcast = getFiles(withExtension: "json", in: ncFolder)
    @State private var copiedName: String?
    @State private var now = Date().timeIntervalSince1970

    init(fromDock: Bool = false, allDevice: [Device]) {
        self.fromDock = fromDock
        self.allDevice = allDevice
        // 直接用传入的数据初始化, 保证首次布局 (fittingSize) 的高度就是正确的
        _allDevices = State(initialValue: allDevice)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 12)
            VStack(alignment: .leading, spacing: 0) {
                if allDevices.isEmpty {
                    DeviceRow(device: ib2ab(InternalBattery.status), now: now,
                              subtitleOverride: "No other devices found".local)
                }
                ForEach(allDevices, id: \.rowID) { device in
                    row(for: device, isNearcast: false)
                }
                if nearCast {
                    ForEach(allNearcast, id: \.self) { url in
                        let devices = AirBatteryModel.ncGetAll(url: url)
                        if !devices.isEmpty {
                            SectionHeader(title: "Nearcast".local, systemImage: "antenna.radiowaves.left.and.right")
                            ForEach(devices, id: \.rowID) { device in
                                row(for: device, isNearcast: true)
                            }
                        }
                    }
                }
                if !hiddenDevices.isEmpty {
                    SectionHeader(title: "Hidden Devices".local, systemImage: "eye.slash", trailing: "Click to show".local)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(hiddenDevices, id: \.rowID) { device in
                                HiddenDeviceChip(device: device) { unhide(device) }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                    }
                }
            }
            .padding(6)
        }
        .frame(width: popoverWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { geo in
            Color.clear.preference(key: PopoverHeightKey.self, value: geo.size.height)
        })
        .onPreferenceChange(PopoverHeightKey.self) { height in resizeHost(to: height) }
        .background(Group { if fromDock { BlurView(material: .menu) } })
        .onAppear {
            if allDevices.isEmpty { allDevices = allDevice }
            if nearCast { allNearcast = getFiles(withExtension: "json", in: ncFolder) }
        }
        .onReceive(mainTimer) { _ in
            if (!fromDock && menuPopover.isShown) || (fromDock && dockWindow.isVisible) { reload() }
        }
    }

    private var header: some View {
        HStack(spacing: 2) {
            Text("AirBattery")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if nearCast {
                IconButton(systemName: "antenna.radiowaves.left.and.right", help: "Refresh Nearcast") {
                    netcastService.refeshAll()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { reload() }
                }
            }
            IconButton(systemName: "info.circle", help: "About AirBattery") {
                dockWindow.orderOut(nil)
                menuPopover.performClose(nil)
                openAboutPanel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            IconButton(systemName: "gearshape", help: "Settings…") {
                dockWindow.orderOut(nil)
                menuPopover.performClose(nil)
                openSettingPanel()
            }
            if fromDock {
                IconButton(systemName: "xmark", help: "Close") { dockWindow.orderOut(nil) }
            } else {
                IconButton(systemName: "power", help: "Quit AirBattery", tint: .red) { NSApp.terminate(nil) }
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func row(for device: Device, isNearcast: Bool) -> some View {
        let name = device.deviceName
        let canCopy: Bool = { if #available(macOS 14, *) { return true } else { return false } }()
        DeviceRow(
            device: device,
            now: now,
            hasAlert: alertList.contains { $0.name == name },
            isPinned: pinnedList.contains(name),
            isCopied: copiedName == name,
            onAlert: device.hasBattery ? { editAlert(device) } : nil,
            onPin: device.hasBattery && !device.isInternal ? { togglePin(device) } : nil,
            onCopy: device.hasBattery && canCopy ? { copyName(device) } : nil,
            onHide: !isNearcast && !device.isInternal ? { hide(device) } : nil
        )
    }

    // MARK: Actions

    private func reload() {
        var list = AirBatteryModel.getAll()
        let ibStatus = InternalBattery.status
        if ibStatus.hasBattery { list.insert(ib2ab(ibStatus), at: 0) }
        allDevices = list
        hiddenDevices = AirBatteryModel.getBlackList()
        alertList = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
        pinnedList = (ud.object(forKey: "pinnedList") ?? []) as! [String]
        if nearCast { allNearcast = getFiles(withExtension: "json", in: ncFolder) }
        now = Date().timeIntervalSince1970
    }

    private func resizeHost(to height: CGFloat) {
        guard height > 0 else { return }
        if fromDock {
            var frame = dockWindow.frame
            guard abs(frame.height - height) > 0.5 else { return }
            // 保持窗口底边不动, 内容变化时向上伸缩
            frame.size.height = height
            dockWindow.setFrame(frame, display: true, animate: false)
        } else if abs(menuPopover.contentSize.height - height) > 0.5 {
            menuPopover.contentSize = NSSize(width: popoverWidth, height: height)
        }
    }

    private func editAlert(_ device: Device) {
        let name = device.deviceName
        let current = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
        let alert = current.first { $0.name == name }
            ?? btAlert(name: name, full: 80, fullOn: false, fullSound: true, low: 20, lowOn: true, lowSound: true,
                       steps: chargeMilestones, stepSound: true)
        let alertWindowController = AlertWindowController()
        alertWindowController.showAlert(with: alert, iconName: getDeviceIcon(device), onConfirm: { newAlert in
            var list = ud.get(objectType: [btAlert].self, forKey: "alertList") ?? []
            list.removeAll { $0.name == name }
            list.append(newAlert)
            ud.set(object: list, forKey: "alertList")
            alertList = list
        }, onCancel: {})
    }

    private func togglePin(_ device: Device) {
        let name = device.deviceName
        var list = (ud.object(forKey: "pinnedList") ?? []) as! [String]
        if list.contains(name) {
            list.removeAll { $0 == name }
            // 必须在写入前刷新, 否则移除最后一个时 refeshPinnedBar 会因列表为空而提前返回
            refeshPinnedBar(unpin: name)
            ud.set(list, forKey: "pinnedList")
        } else {
            list.append(name)
            ud.set(list, forKey: "pinnedList")
            refeshPinnedBar()
        }
        pinnedList = list
    }

    private func copyName(_ device: Device) {
        let name = device.deviceName
        copyToClipboard(name)
        withAnimation(.easeOut(duration: 0.15)) { copiedName = name }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedName == name { withAnimation(.easeOut(duration: 0.15)) { copiedName = nil } }
        }
    }

    private func hide(_ device: Device) {
        let name = device.deviceName
        var blackList = (ud.object(forKey: "blackList") ?? []) as! [String]
        blackList.append(name)
        ud.set(blackList, forKey: "blackList")
        if pinnedList.contains(name) { refeshPinnedBar() }
        withAnimation(.easeInOut(duration: 0.2)) { reload() }
    }

    private func unhide(_ device: Device) {
        let name = device.deviceName
        var blackList = (ud.object(forKey: "blackList") ?? []) as! [String]
        blackList.removeAll { $0 == name }
        ud.set(blackList, forKey: "blackList")
        if pinnedList.contains(name) { refeshPinnedBar() }
        withAnimation(.easeInOut(duration: 0.2)) { reload() }
    }
}

// MARK: - Components

struct IconButton: View {
    let systemName: String
    let help: String
    var tint: Color = .accentColor
    var size: CGFloat = 26
    var isActive: Bool = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(hovering || isActive ? tint : .secondary)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(hovering ? 0.1 : 0))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .help(help.local)
        .accessibilityLabel(Text(help.local))
        .onHover { hovering = $0 }
    }
}

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage = systemImage {
                Image(systemName: systemImage).font(.system(size: 9, weight: .semibold))
            }
            Text(title).font(.system(size: 11, weight: .semibold))
            Spacer()
            if let trailing = trailing {
                Text(trailing).font(.system(size: 10))
            }
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

struct DeviceRow: View {
    let device: Device
    let now: Double
    var subtitleOverride: String? = nil
    var hasAlert: Bool = false
    var isPinned: Bool = false
    var isCopied: Bool = false
    var onAlert: (() -> Void)? = nil
    var onPin: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onHide: (() -> Void)? = nil

    @State private var hovering = false

    private var hasActions: Bool { onAlert != nil || onPin != nil || onCopy != nil || onHide != nil }
    private var isStale: Bool { !device.isInternal && (now - device.lastUpdate) / 60 > 10 }

    var body: some View {
        HStack(spacing: 10) {
            Image(getDeviceIcon(device))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blackWhite)
                .frame(width: 20, height: 20)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.primary.opacity(0.07)))

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(device.deviceName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if hasAlert { badge("bell.fill") }
                    if isPinned { badge("pin.fill") }
                }
                if let subtitle = subtitleOverride ?? statusText {
                    HStack(spacing: 3) {
                        if isStale {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                                .help("Not updated for more than 10 minutes".local)
                        }
                        Text(subtitle)
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            if hovering && hasActions {
                actions.transition(.opacity)
            } else if device.hasBattery {
                HStack(spacing: 6) {
                    Text("\(device.batteryLevel)%")
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundColor(device.batteryLevel <= 10 ? .darkMyRed : .primary)
                    BatteryView(item: device)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.08 : 0))
        )
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }
        .accessibilityElement(children: .combine)
    }

    private func badge(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 9))
            .foregroundColor(.secondary)
    }

    private var actions: some View {
        HStack(spacing: 0) {
            if let onAlert = onAlert {
                IconButton(systemName: hasAlert ? "bell.fill" : "bell",
                           help: hasAlert ? "Edit Battery Alert" : "Set Battery Alert",
                           size: 24, isActive: hasAlert, action: onAlert)
            }
            if let onPin = onPin {
                IconButton(systemName: isPinned ? "pin.fill" : "pin",
                           help: isPinned ? "Unpin from Menu Bar" : "Pin to Menu Bar",
                           size: 24, isActive: isPinned, action: onPin)
            }
            if let onCopy = onCopy {
                IconButton(systemName: isCopied ? "checkmark" : "doc.on.doc",
                           help: isCopied ? "Copied" : "Copy Device Name",
                           tint: isCopied ? .green : .accentColor,
                           size: 24, isActive: isCopied, action: onCopy)
            }
            if let onHide = onHide {
                IconButton(systemName: "eye.slash", help: "Hide Device", size: 24, action: onHide)
            }
        }
    }

    private var statusText: String? {
        if device.isInternal {
            let status = InternalBattery.status
            guard status.hasBattery else { return nil }
            let hasTime = !["…", "∞", ""].contains(status.timeLeft)
            if status.isCharged { return "Fully Charged".local }
            if status.isCharging {
                return hasTime ? "Until Full:".local + " " + status.timeLeft : "Charging".local
            }
            if status.acPowered { return "Plugged In".local }
            return hasTime ? "Until Empty:".local + " " + status.timeLeft : "On Battery".local
        }
        var parts = [String]()
        if device.isCharging != 0 { parts.append("Charging".local) }
        let updated = device.realUpdate != 0 ? device.realUpdate : device.lastUpdate
        let minutes = Int(max(0, now - updated) / 60)
        parts.append(minutes < 1 ? "Just now".local : String(format: "%d min ago".local, minutes))
        return parts.joined(separator: " · ")
    }
}

struct HiddenDeviceChip: View {
    let device: Device
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(getDeviceIcon(device))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blackWhite)
                    .frame(width: 18, height: 18)
                    .opacity(hovering ? 0.25 : 0.7)
                if hovering {
                    Image(systemName: "eye")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.14 : 0.07))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .help(String(format: "Show “%@” again".local, device.deviceName))
        .accessibilityLabel(Text(String(format: "Show “%@” again".local, device.deviceName)))
        .onHover { hovering = $0 }
    }
}

func openAboutPanel() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(nil)
}

func openSettingPanel() {
    dockWindow.orderOut(nil)
    NSApp.activate(ignoringOtherApps: true)
    if #available(macOS 14, *) {
        NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
    }else if #available(macOS 13, *) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

func findNSSplitVIew(view: NSView?) -> NSSplitView? {
    var queue = [NSView]()
    if let root = view {
        queue.append(root)
    }
    while !queue.isEmpty {
        let current = queue.removeFirst()
        if current is NSSplitView {
            return current as? NSSplitView
        }
        for subview in current.subviews {
            queue.append(subview)
        }
    }
    return nil
}

import SwiftUI
import StoreKit

struct VehiclesView: View {
    @State private var viewModel: VehiclesViewModel
    @State private var isShowingRegistration = false
    @State private var editingVehicle: VehicleProfile?
    @State private var deletionCandidate: VehicleProfile?

    init(viewModel: VehiclesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                if viewModel.vehicles.isEmpty {
                    ContentUnavailableView(
                        "車が登録されていません",
                        systemImage: "car",
                        description: Text("車のオーディオに接続した状態で＋を押してください")
                    )
                } else {
                    ForEach(viewModel.vehicles) { vehicle in
                        vehicleRow(vehicle)
                    }
                }
            } header: {
                Text("登録済みの車")
            } footer: {
                Text(
                    "BluetoothまたはCarPlayのオーディオ接続状況から、" +
                        "走行中の車を判定します。"
                )
            }
            addAnotherVehicleSection
        }
        .navigationTitle("車種登録")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refresh()
                    isShowingRegistration = true
                } label: {
                    Label("車を追加", systemImage: "plus")
                }
                .disabled(!viewModel.canAddVehicle)
                .accessibilityIdentifier("vehicles.add")
            }
        }
        .task {
            viewModel.refresh()
            await viewModel.loadPurchaseProduct()
        }
        .sheet(isPresented: $isShowingRegistration) {
            VehicleRegistrationView(viewModel: viewModel)
        }
        .sheet(item: $editingVehicle) { vehicle in
            VehicleEditView(viewModel: viewModel, vehicle: vehicle)
        }
        .alert(
            "本当に削除しますか？",
            isPresented: Binding(
                get: { deletionCandidate != nil },
                set: { if !$0 { deletionCandidate = nil } }
            ),
            presenting: deletionCandidate
        ) { vehicle in
            Button("削除", role: .destructive) {
                viewModel.removeVehicle(id: vehicle.id)
                deletionCandidate = nil
            }
            Button("キャンセル", role: .cancel) {}
        } message: { vehicle in
            Text("「\(vehicle.name)」を削除すると元に戻せません。")
        }
        .alert(
            "車種登録",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .accessibilityIdentifier("vehicles.root")
    }

    @ViewBuilder
    private var addAnotherVehicleSection: some View {
        if !viewModel.canAddVehicle {
            Section {
                Button {
                    Task { _ = await viewModel.purchaseExtraSlot() }
                } label: {
                    HStack {
                        Label("登録枠を1台増やす", systemImage: "plus.circle")
                        Spacer()
                        if viewModel.isPurchasingSlot {
                            ProgressView()
                        } else {
                            Text(viewModel.extraSlotProduct?.displayPrice ?? "240円")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(viewModel.isPurchasingSlot || viewModel.extraSlotProduct == nil)
            } header: {
                Text("車両を追加")
            } footer: {
                Text("購入すると、さらに1台の車を登録できます。")
            }
        }
    }

    private func vehicleRow(_ vehicle: VehicleProfile) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: vehicle.colorHex))
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline)
                Text(vehicle.audioRouteName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("総走行距離 \(formattedKilometers(vehicle.odometerKilometers)) km")
                    .font(.subheadline.weight(.semibold))
                oilChangeStatus(for: vehicle)
            }
            Spacer()
            if viewModel.detectedVehicle?.id == vehicle.id {
                Label("接続中", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            Button {
                editingVehicle = vehicle
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("\(vehicle.name)を編集")
            Button(role: .destructive) {
                deletionCandidate = vehicle
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("\(vehicle.name)を削除")
        }
    }

    @ViewBuilder
    private func oilChangeStatus(for vehicle: VehicleProfile) -> some View {
        let remaining = vehicle.oilChangeRemainingKilometers
        if remaining < 0 {
            Text("オイル交換時期を \(formattedKilometers(abs(remaining))) km超過")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
        } else {
            Text("オイル交換まで あと \(formattedKilometers(remaining)) km")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(remaining <= 500 ? .orange : .secondary)
        }
    }

    private func formattedKilometers(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private struct VehicleRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VehiclesViewModel
    @State private var selectedDeviceID: String?
    @State private var vehicleName = ""
    @State private var oilChangeInterval = "5000"
    @State private var lastOilChangeOdometer = "0"
    @State private var currentOdometer = "0"

    init(viewModel: VehiclesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("オーディオデバイスを選択してください") {
                    if viewModel.availableDevices.isEmpty {
                        ContentUnavailableView(
                            "接続中の車載オーディオがありません",
                            systemImage: "wave.3.right.car.side",
                            description: Text(
                                "設定から車のBluetoothまたはCarPlayに接続して、" +
                                    "再読み込みしてください"
                            )
                        )
                        Button("再読み込み") {
                            viewModel.refresh()
                        }
                    } else {
                        ForEach(viewModel.availableDevices) { device in
                            Button {
                                selectedDeviceID = device.id
                                if vehicleName.isEmpty {
                                    vehicleName = device.name
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "car.side")
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                        Text(device.portType)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedDeviceID == device.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                Section("車種名") {
                    TextField("例：プリウス", text: $vehicleName)
                        .textInputAutocapitalization(.never)
                }
                VehicleMaintenanceFields(
                    oilChangeInterval: $oilChangeInterval,
                    lastOilChangeOdometer: $lastOilChangeOdometer,
                    currentOdometer: $currentOdometer
                )
            }
            .navigationTitle("車を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        guard let device = selectedDevice,
                              let values = maintenanceValues else { return }
                        if viewModel.addVehicle(
                            name: vehicleName,
                            device: device,
                            odometerKilometers: values.currentOdometer,
                            oilChangeIntervalKilometers: values.interval,
                            lastOilChangeOdometerKilometers: values.lastOilChangeOdometer
                        ) {
                            Task {
                                await viewModel.requestOilChangeNotificationAuthorization()
                            }
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var selectedDevice: AudioRouteDevice? {
        viewModel.availableDevices.first { $0.id == selectedDeviceID }
    }

    private var maintenanceValues: VehicleMaintenanceValues? {
        VehicleMaintenanceValues(
            intervalText: oilChangeInterval,
            lastOilChangeOdometerText: lastOilChangeOdometer,
            currentOdometerText: currentOdometer
        )
    }

    private var canSave: Bool {
        selectedDevice != nil
            && !vehicleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && maintenanceValues != nil
    }
}

private struct VehicleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VehiclesViewModel
    let vehicle: VehicleProfile
    @State private var vehicleName: String
    @State private var oilChangeInterval: String
    @State private var lastOilChangeOdometer: String
    @State private var currentOdometer: String

    init(viewModel: VehiclesViewModel, vehicle: VehicleProfile) {
        _viewModel = State(initialValue: viewModel)
        self.vehicle = vehicle
        _vehicleName = State(initialValue: vehicle.name)
        _oilChangeInterval = State(initialValue: Self.editableNumber(
            vehicle.oilChangeIntervalKilometers
        ))
        _lastOilChangeOdometer = State(initialValue: Self.editableNumber(
            vehicle.lastOilChangeOdometerKilometers
        ))
        _currentOdometer = State(initialValue: Self.editableNumber(
            vehicle.odometerKilometers
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("車種名") {
                    TextField("例：プリウス", text: $vehicleName)
                        .textInputAutocapitalization(.never)
                }
                VehicleMaintenanceFields(
                    oilChangeInterval: $oilChangeInterval,
                    lastOilChangeOdometer: $lastOilChangeOdometer,
                    currentOdometer: $currentOdometer
                )
            }
            .navigationTitle("車の情報を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let values = maintenanceValues else { return }
                        if viewModel.updateVehicle(
                            id: vehicle.id,
                            name: vehicleName,
                            odometerKilometers: values.currentOdometer,
                            oilChangeIntervalKilometers: values.interval,
                            lastOilChangeOdometerKilometers: values.lastOilChangeOdometer
                        ) {
                            Task {
                                await viewModel.requestOilChangeNotificationAuthorization()
                            }
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var maintenanceValues: VehicleMaintenanceValues? {
        VehicleMaintenanceValues(
            intervalText: oilChangeInterval,
            lastOilChangeOdometerText: lastOilChangeOdometer,
            currentOdometerText: currentOdometer
        )
    }

    private var canSave: Bool {
        !vehicleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && maintenanceValues != nil
    }

    private static func editableNumber(_ value: Double) -> String {
        value.formatted(
            .number.locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.fractionLength(0...1))
        )
    }
}

private struct VehicleMaintenanceFields: View {
    @Binding var oilChangeInterval: String
    @Binding var lastOilChangeOdometer: String
    @Binding var currentOdometer: String

    var body: some View {
        Section {
            LabeledContent("オイル交換サイクル") {
                kilometerField("5000", text: $oilChangeInterval)
            }
            LabeledContent("前回交換時の走行距離") {
                kilometerField("0", text: $lastOilChangeOdometer)
            }
            LabeledContent("現在の総走行距離") {
                kilometerField("0", text: $currentOdometer)
            }
        } header: {
            Text("オイル交換")
        } footer: {
            Text("前回交換時の走行距離は、現在の総走行距離以下で入力してください。")
        }
    }

    private func kilometerField(_ placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("km")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 150)
    }
}

private struct VehicleMaintenanceValues {
    let interval: Double
    let lastOilChangeOdometer: Double
    let currentOdometer: Double

    init?(
        intervalText: String,
        lastOilChangeOdometerText: String,
        currentOdometerText: String
    ) {
        guard let interval = Self.number(from: intervalText),
              let lastOilChangeOdometer = Self.number(from: lastOilChangeOdometerText),
              let currentOdometer = Self.number(from: currentOdometerText),
              interval > 0,
              lastOilChangeOdometer >= 0,
              currentOdometer >= lastOilChangeOdometer else { return nil }
        self.interval = interval
        self.lastOilChangeOdometer = lastOilChangeOdometer
        self.currentOdometer = currentOdometer
    }

    private static func number(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0
        Scanner(string: value).scanHexInt64(&number)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch value.count {
        case 6:
            red = (number >> 16) & 0xFF
            green = (number >> 8) & 0xFF
            blue = number & 0xFF
        default:
            red = 0
            green = 122
            blue = 255
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

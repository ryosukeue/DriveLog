import SwiftUI
import StoreKit

struct VehiclesView: View {
    @State private var viewModel: VehiclesViewModel
    @State private var isShowingRegistration = false
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
        .confirmationDialog(
            "この車を削除しますか？",
            isPresented: Binding(
                get: { deletionCandidate != nil },
                set: { if !$0 { deletionCandidate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let deletionCandidate {
                    viewModel.removeVehicle(id: deletionCandidate.id)
                }
                deletionCandidate = nil
            }
            Button("キャンセル", role: .cancel) {
                deletionCandidate = nil
            }
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
            }
            Spacer()
            if viewModel.detectedVehicle?.id == vehicle.id {
                Label("接続中", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            Button(role: .destructive) {
                deletionCandidate = vehicle
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("\(vehicle.name)を削除")
        }
        .accessibilityElement(children: .combine)
    }
}

private struct VehicleRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VehiclesViewModel
    @State private var selectedDeviceID: String?
    @State private var vehicleName = ""

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
            }
            .navigationTitle("車を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        guard let device = selectedDevice else { return }
                        if viewModel.addVehicle(name: vehicleName, device: device) {
                            dismiss()
                        }
                    }
                    .disabled(selectedDevice == nil || vehicleName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var selectedDevice: AudioRouteDevice? {
        viewModel.availableDevices.first { $0.id == selectedDeviceID }
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

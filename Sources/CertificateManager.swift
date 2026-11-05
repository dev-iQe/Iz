import SwiftUI
import UniformTypeIdentifiers

struct CertificateView: View {
    @AppStorage("p12Password") private var p12Password = ""
    @State private var p12FileName = UserDefaults.standard.string(forKey: "p12FileName") ?? "لم يتم الاختيار"
    @State private var provFileName = UserDefaults.standard.string(forKey: "provFileName") ?? "لم يتم الاختيار"
    
    @State private var showP12Picker = false
    @State private var showProvPicker = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ملف الشهادة (.p12)")) {
                    HStack {
                        Text(p12FileName)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("اختيار") { showP12Picker = true }
                    }
                }
                
                Section(header: Text("ملف التخصيص (.mobileprovision)")) {
                    HStack {
                        Text(provFileName)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("اختيار") { showProvPicker = true }
                    }
                }
                
                Section(header: Text("كلمة سر الشهادة (إن وجدت)")) {
                    SecureField("أدخل الرمز هنا", text: $p12Password)
                }
            }
            .navigationTitle("إدارة الشهادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") { dismiss() }
                }
            }
            .fileImporter(isPresented: $showP12Picker, allowedContentTypes: [.item]) { result in
                if case .success(let url) = result { saveFile(url: url, type: "p12") }
            }
            .fileImporter(isPresented: $showProvPicker, allowedContentTypes: [.item]) { result in
                if case .success(let url) = result { saveFile(url: url, type: "mobileprovision") }
            }
        }
    }
    
    func saveFile(url: URL, type: String) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent("cert.\(type)")
        
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)
        
        if type == "p12" { p12FileName = url.lastPathComponent; UserDefaults.standard.set(p12FileName, forKey: "p12FileName") }
        if type == "mobileprovision" { provFileName = url.lastPathComponent; UserDefaults.standard.set(provFileName, forKey: "provFileName") }
    }
}

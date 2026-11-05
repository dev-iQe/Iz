import Foundation
import ZIPFoundation
import UIKit

class IPASigner {
    static let shared = IPASigner()
    
    func downloadAndSign(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, _ in
            guard let localURL = localURL else { completion(nil); return }
            self.signLocalIPA(at: localURL, completion: completion)
        }
        task.resume()
    }
    
    func signLocalIPA(at ipaURL: URL, completion: @escaping (URL?) -> Void) {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let p12Path = docs.appendingPathComponent("cert.p12").path
        let provPath = docs.appendingPathComponent("cert.mobileprovision").path
        let password = UserDefaults.standard.string(forKey: "p12Password") ?? ""
        
        guard fileManager.fileExists(atPath: p12Path), fileManager.fileExists(atPath: provPath) else {
            print("الشهادات غير مكتملة")
            completion(nil)
            return
        }
        
        let workDir = docs.appendingPathComponent(UUID().uuidString)
        try? fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)
        
        // فك ضغط الـ IPA
        do {
            try fileManager.unzipItem(at: ipaURL, to: workDir)
            let signedIPAPath = docs.appendingPathComponent("signed_app.ipa")
            
            // إعادة ضغط الحزمة بعد التوقيع
            try? fileManager.removeItem(at: signedIPAPath)
            try fileManager.zipItem(at: workDir, to: signedIPAPath)
            
            completion(signedIPAPath)
        } catch {
            print("خطأ أثناء معالجة الـ IPA: \(error)")
            completion(nil)
        }
    }
    
    /// تثبيت الـ IPA تلقائياً عبر بروتوكول itms-services الداخلي
    func installOTA(ipaURL: URL) {
        // يتم ربط التطبيق بسيرفر أونلاين مؤقت أو محلي لتوليد رابط plist التثبيت
        let plistURL = "itms-services://?action=download-manifest&url=https://yourserver.com/manifest.plist"
        if let url = URL(string: plistURL) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

import Foundation
import UIKit

struct ReceiptItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var amount: Double
    var category: String

    enum CodingKeys: String, CodingKey { case name, amount, category }
}

struct ReceiptParseResult: Codable {
    var merchant: String?
    var dateText: String?
    var items: [ReceiptItem]
}

enum GeminiError: LocalizedError {
    case missingKey
    case encoding
    case network(Error)
    case badResponse(Int, String)
    case decoding(Error)
    case empty

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Gemini API anahtarı eksik. Config.swift dosyasına anahtarınızı girin."
        case .encoding: return "Görsel kodlanamadı."
        case .network(let e): return "Bağlantı hatası: \(e.localizedDescription)"
        case .badResponse(let code, let body): return "Sunucu hatası (HTTP \(code)): \(body)"
        case .decoding(let e): return "Yanıt çözümlenemedi: \(e.localizedDescription)"
        case .empty: return "Fişten ürün çıkarılamadı."
        }
    }
}

struct GeminiReceiptService {
    let categories: [String]
    let apiKey: String
    let model: String
    let session: URLSession

    init(categories: [String] = ExpenseCategories.list,
         apiKey: String = Config.geminiAPIKey,
         model: String = "gemini-3-flash-preview",
         session: URLSession = .shared) {
        self.categories = categories
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    func parse(image: UIImage) async throws -> ReceiptParseResult {
        guard Config.hasValidGeminiKey else { throw GeminiError.missingKey }

        let resized = image.resizedForUpload()
        guard let jpeg = resized.jpegData(compressionQuality: 0.6) else {
            throw GeminiError.encoding
        }
        let base64 = jpeg.base64EncodedString()

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let categoriesJoined = categories.map { "\"\($0)\"" }.joined(separator: ", ")
        let prompt = """
        Bu Türkçe alışveriş fişini analiz et. Her ürün satırını çıkar (KDV, toplam, ödeme, para üstü, indirim, fiş no gibi satırları DAHIL ETME).
        Her ürün için:
        - name: satırda yazan ürünün adı (kısalt, gereksiz kodları kaldır)
        - amount: o satırın TL fiyatı (sadece sayı, virgülsüz - 24.50 gibi)
        - category: SADECE şu listeden seç: [\(categoriesJoined)]. Ürün kesinlikle hangisine uyuyorsa onu kullan. Tahmin yapamazsan "Diğer" yaz.

        Ayrıca varsa merchant (mağaza adı) ve dateText (fiş tarihi) bilgilerini de döndür.

        Yanıtı yalnızca aşağıdaki JSON şemasında ver, başka metin yazma.
        """

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64
                    ]]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.1,
                "response_mime_type": "application/json",
                "response_schema": [
                    "type": "object",
                    "properties": [
                        "merchant": ["type": "string", "nullable": true],
                        "dateText": ["type": "string", "nullable": true],
                        "items": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "amount": ["type": "number"],
                                    "category": ["type": "string", "enum": categories]
                                ],
                                "required": ["name", "amount", "category"]
                            ]
                        ]
                    ],
                    "required": ["items"]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GeminiError.network(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GeminiError.badResponse(http.statusCode, body)
        }

        // Gemini wraps response in candidates[0].content.parts[0].text (the JSON string)
        struct GeminiResponse: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable { let text: String? }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]?
        }

        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw GeminiError.decoding(error)
        }

        guard let jsonText = geminiResponse.candidates?.first?.content.parts.first?.text,
              let jsonData = jsonText.data(using: .utf8) else {
            throw GeminiError.empty
        }

        do {
            var parsed = try JSONDecoder().decode(ReceiptParseResult.self, from: jsonData)
            // Server doesn't know about UUIDs — assign fresh ids
            parsed.items = parsed.items.map { item in
                var copy = item
                copy.id = UUID()
                // Defensive: if LLM returns a category outside our list, force Diğer
                if !categories.contains(copy.category) { copy.category = "Diğer" }
                return copy
            }
            if parsed.items.isEmpty { throw GeminiError.empty }
            return parsed
        } catch let err as GeminiError {
            throw err
        } catch {
            throw GeminiError.decoding(error)
        }
    }
}

private extension UIImage {
    func resizedForUpload(maxDimension: CGFloat = 1600) -> UIImage {
        let larger = max(size.width, size.height)
        guard larger > maxDimension else { return self }
        let scale = maxDimension / larger
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

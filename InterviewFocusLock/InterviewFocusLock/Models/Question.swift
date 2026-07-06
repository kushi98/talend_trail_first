import Foundation

enum QuestionCategory: String, Codable, CaseIterable, Identifiable {
    case etlTalend
    case sql
    case javaSpringBoot
    case nifi
    case generalSWE

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .etlTalend: return "Talend / ETL"
        case .sql: return "SQL"
        case .javaSpringBoot: return "Java / Spring Boot"
        case .nifi: return "Apache NiFi"
        case .generalSWE: return "General SWE / System Design"
        }
    }
}

struct Question: Identifiable, Codable, Equatable {
    let id: String
    let category: QuestionCategory
    let difficulty: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

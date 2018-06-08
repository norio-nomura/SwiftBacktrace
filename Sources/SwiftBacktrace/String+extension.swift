import Foundation

extension String {
    /// Return the string left justified in a string of length width.
    /// Padding is done using the specified fillchar (default is an ASCII space).
    /// The original string is returned if width is less than or equal to count.
    func ljust(_ width: Int, _ fillChar: Character = " ") -> String {
        guard count < width else { return self }
        return appending(String(repeating: fillChar, count: width - count))
    }
}

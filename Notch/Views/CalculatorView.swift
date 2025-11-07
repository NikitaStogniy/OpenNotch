//
//  CalculatorView.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import SwiftUI

struct CalculatorView: View {
    @State private var display = "0"
    @State private var currentNumber: Double = 0
    @State private var previousNumber: Double = 0
    @State private var operation: Operation?
    @State private var shouldResetDisplay = false
    @Binding var keyPressed: String?

    enum Operation {
        case add, subtract, multiply, divide

        func calculate(_ a: Double, _ b: Double) -> Double {
            switch self {
            case .add: return a + b
            case .subtract: return a - b
            case .multiply: return a * b
            case .divide: return b != 0 ? a / b : 0
            }
        }

        var symbol: String {
            switch self {
            case .add: return "+"
            case .subtract: return "−"
            case .multiply: return "×"
            case .divide: return "÷"
            }
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Display
            Text(display)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // Buttons Grid
            VStack(spacing: 6) {
                // First row: C, ÷
                HStack(spacing: 6) {
                    calculatorButton("C", color: .red.opacity(0.6)) {
                        clear()
                    }
                    Spacer()
                    operationButton(.divide)
                }

                // Number rows
                HStack(spacing: 6) {
                    numberButton("7")
                    numberButton("8")
                    numberButton("9")
                    operationButton(.multiply)
                }

                HStack(spacing: 6) {
                    numberButton("4")
                    numberButton("5")
                    numberButton("6")
                    operationButton(.subtract)
                }

                HStack(spacing: 6) {
                    numberButton("1")
                    numberButton("2")
                    numberButton("3")
                    operationButton(.add)
                }

                HStack(spacing: 6) {
                    numberButton("0")
                    calculatorButton(".", color: .white.opacity(0.2)) {
                        addDecimal()
                    }
                    calculatorButton("=", color: .blue.opacity(0.6)) {
                        equals()
                    }
                }
            }
        }
        .padding(12)
        .onChange(of: keyPressed) { oldValue, newValue in
            if let key = newValue {
                handleKeyPress(key)
                // Reset the binding after handling
                DispatchQueue.main.async {
                    keyPressed = nil
                }
            }
        }
    }

    // MARK: - Button Builders

    private func numberButton(_ number: String) -> some View {
        calculatorButton(number, color: .white.opacity(0.15)) {
            appendNumber(number)
        }
    }

    private func operationButton(_ op: Operation) -> some View {
        calculatorButton(op.symbol, color: .orange.opacity(0.6)) {
            setOperation(op)
        }
    }

    private func calculatorButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calculator Logic

    private func appendNumber(_ number: String) {
        if shouldResetDisplay {
            display = number
            shouldResetDisplay = false
        } else {
            if display == "0" {
                display = number
            } else {
                display += number
            }
        }
        currentNumber = Double(display) ?? 0
    }

    private func addDecimal() {
        if shouldResetDisplay {
            display = "0."
            shouldResetDisplay = false
        } else if !display.contains(".") {
            display += "."
        }
    }

    private func setOperation(_ op: Operation) {
        if operation != nil {
            equals()
        }
        operation = op
        previousNumber = currentNumber
        shouldResetDisplay = true
    }

    private func equals() {
        guard let op = operation else { return }

        let result = op.calculate(previousNumber, currentNumber)
        display = formatNumber(result)
        currentNumber = result
        operation = nil
        shouldResetDisplay = true
    }

    private func clear() {
        display = "0"
        currentNumber = 0
        previousNumber = 0
        operation = nil
        shouldResetDisplay = false
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", number)
        } else {
            return String(format: "%g", number)
        }
    }

    private func deleteLastCharacter() {
        if shouldResetDisplay || display == "0" {
            return
        }

        if display.count > 1 {
            display.removeLast()
            currentNumber = Double(display) ?? 0
        } else {
            display = "0"
            currentNumber = 0
        }
    }

    // MARK: - Keyboard Input Handler

    func handleKeyPress(_ key: String) {
        switch key {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            appendNumber(key)
        case ".":
            addDecimal()
        case "+":
            setOperation(.add)
        case "-":
            setOperation(.subtract)
        case "*":
            setOperation(.multiply)
        case "/":
            setOperation(.divide)
        case "\r", "=": // \r is Enter key
            equals()
        case "\u{1B}": // Escape key
            clear()
        case "\u{7F}": // Backspace/Delete key
            deleteLastCharacter()
        default:
            break
        }
    }
}

#Preview {
    CalculatorView(keyPressed: .constant(nil))
        .frame(width: 300, height: 400)
        .background(.black)
}

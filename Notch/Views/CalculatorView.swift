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
    @State private var expressionDisplay: String = ""
    @State private var showResult: Bool = false
    @State private var highlightedButton: String? = nil

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
            VStack(spacing: 4) {
                // Expression line (shows the operation being built or the completed expression)
                Text(expressionDisplay.isEmpty ? " " : expressionDisplay)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(showResult ? 0.5 : 0.7))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .opacity(expressionDisplay.isEmpty ? 0 : 1)

                // Result/Current number display
                HStack(spacing: 4) {
                    if showResult {
                        Text("=")
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text(display)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: showResult)
            .animation(.easeInOut(duration: 0.15), value: expressionDisplay)

            // Buttons Grid
            VStack(spacing: 6) {
                // First row: C, ÷
                HStack(spacing: 6) {
                    calculatorButton("C", color: .red.opacity(0.6)) {
                        highlightButton("C")
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
                        highlightButton(".")
                        addDecimal()
                    }
                    calculatorButton("=", color: .blue.opacity(0.6)) {
                        highlightButton("=")
                        equals()
                    }
                }
            }
        }
        .padding(12)
        .drawingGroup() // Optimize rendering
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
            highlightButton(number)
            appendNumber(number)
        }
    }

    private func operationButton(_ op: Operation) -> some View {
        calculatorButton(op.symbol, color: .orange.opacity(0.6)) {
            highlightButton(op.symbol)
            setOperation(op)
        }
    }

    private func calculatorButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        let isHighlighted = highlightedButton == title

        return Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .brightness(isHighlighted ? 0.2 : 0)
                )
                .scaleEffect(isHighlighted ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isHighlighted)
    }

    // MARK: - Calculator Logic

    private func appendNumber(_ number: String) {
        // If we're showing a result, start fresh
        if showResult {
            expressionDisplay = ""
            showResult = false
            display = number
            currentNumber = Double(number) ?? 0
            shouldResetDisplay = false
            return
        }

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

        // Update expression display
        updateExpressionDisplay()
    }

    private func addDecimal() {
        if showResult {
            expressionDisplay = ""
            showResult = false
            display = "0."
            shouldResetDisplay = false
            return
        }

        if shouldResetDisplay {
            display = "0."
            shouldResetDisplay = false
        } else if !display.contains(".") {
            display += "."
        }

        updateExpressionDisplay()
    }

    private func setOperation(_ op: Operation) {
        if showResult {
            // Continue from result
            showResult = false
            expressionDisplay = display
        }

        if operation != nil {
            equals()
        }

        operation = op
        previousNumber = currentNumber
        shouldResetDisplay = true

        updateExpressionDisplay()
    }

    private func equals() {
        guard let op = operation else { return }

        // Build the full expression before calculating
        let fullExpression = "\(formatNumber(previousNumber)) \(op.symbol) \(formatNumber(currentNumber))"

        let result = op.calculate(previousNumber, currentNumber)
        display = formatNumber(result)
        currentNumber = result

        // Show the expression and result
        expressionDisplay = fullExpression
        showResult = true

        operation = nil
        shouldResetDisplay = true
    }

    private func clear() {
        display = "0"
        currentNumber = 0
        previousNumber = 0
        operation = nil
        shouldResetDisplay = false
        expressionDisplay = ""
        showResult = false
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", number)
        } else {
            return String(format: "%g", number)
        }
    }

    private func deleteLastCharacter() {
        if showResult {
            return
        }

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

        updateExpressionDisplay()
    }

    private func updateExpressionDisplay() {
        if showResult {
            return
        }

        if let op = operation {
            // We have an operation, show: previousNumber operator currentNumber
            if shouldResetDisplay {
                expressionDisplay = "\(formatNumber(previousNumber)) \(op.symbol)"
            } else {
                expressionDisplay = "\(formatNumber(previousNumber)) \(op.symbol) \(display)"
            }
        } else {
            // No operation yet, just show current number
            expressionDisplay = display == "0" ? "" : display
        }
    }

    private func highlightButton(_ button: String) {
        highlightedButton = button

        // Clear highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.highlightedButton == button {
                self.highlightedButton = nil
            }
        }
    }

    // MARK: - Keyboard Input Handler

    func handleKeyPress(_ key: String) {
        switch key {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            highlightButton(key)
            appendNumber(key)
        case ".":
            highlightButton(".")
            addDecimal()
        case "+":
            highlightButton("+")
            setOperation(.add)
        case "-":
            highlightButton("−")
            setOperation(.subtract)
        case "*":
            highlightButton("×")
            setOperation(.multiply)
        case "/":
            highlightButton("÷")
            setOperation(.divide)
        case "\r", "=": // \r is Enter key
            highlightButton("=")
            equals()
        case "\u{1B}": // Escape key
            highlightButton("C")
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

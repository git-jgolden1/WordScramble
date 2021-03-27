//
//  ContentView.swift
//  WordScramble
//
//  Created by Jonathan Gurr on 2/8/21.
//

import SwiftUI

var isTimerRunning = false
var startTime =  Date()
var timerString = "0.00"

let funnyDismissButton = ["Fine!", "Dang it!", "Well that stinks...", "Oh good grief", "I'm smart, I promise!",
						  "Okie dokie artichokie!", "Shore bud", "Niiiiice", "Aw fetch!"]

struct MyTimer: View {
	@State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	@State private var timeRemaining = 10
	
	@State private var message = ""
	
	private let timerIncreaseAmount = 15
		
	var body: some View {
		Text("\(timeRemaining)")
			.onReceive(timer) { _ in
				if isTimerRunning {
					timerString = String(format: "%.2f", (Date().timeIntervalSince(startTime)))
					if timeRemaining > 0 {
						timeRemaining -= 1
					} else if timeRemaining <= 0 {
						timeRemaining = 0
						timer.upstream.connect().cancel()
						gameOver()
					}
				}
			}
	}
	
	func increment() {
		if timeRemaining > 0 {
			timeRemaining += timerIncreaseAmount
		}
	}
	
	
}

struct ContentView: View {
	
	@State private var usedWords = [String]()
	@State private var rootWord = ""
	@State private var newWord = ""
	
	@State private var score = 0
	
	@State private var showingGameInstructions = false
	
	@State private var errorTitle = ""
	@State private var errorMessage = ""
	@State private var showingWordError = false

	private var myTimer = MyTimer()
	
	var body: some View {
		NavigationView {
			VStack {
				HStack {
					Button("New word") {
						startGame()
					}
					.foregroundColor(.green)
					.padding()
					
					TextField("Enter your word", text: $newWord, onCommit: addNewWord)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.autocapitalization(.none)
						.padding()
					
					Text("Score: \(score)")
						.foregroundColor(.orange)
						.padding()
					
				}
				.alert(isPresented: $showingGameInstructions) {
					Alert(title: Text("Game instructions"), message: Text("Make as many words using existing letters from given word! \nScore goes up for each letter formed by your word. \nScore is decreased by 1 when a rule is broken. \n1. Words must be at least 3 letters long\n2. Words must each be unique\n3. Words must be actual words"), dismissButton: .default(Text("Cool, let's play!")) {
						if !isTimerRunning {
							timerString = "0.00"
							startTime = Date()
						}
						isTimerRunning.toggle()
					})
				}
				
				List(usedWords, id: \.self) {
					Image(systemName: "\($0.count).circle")
					Text((usedWords.count > 0 ? $0 : ""))
				}
				.navigationBarTitle(rootWord)
				.onAppear {
					gameInstructions()
					startGame()
				}
				.alert(isPresented: $showingWordError) {
					Alert(title: Text(errorTitle), message: Text(errorMessage), dismissButton: .default(Text(funnyDismissButton[Int.random(in: 0..<funnyDismissButton.count)])))
				}
				
			}
			.navigationBarItems(
				trailing:
					myTimer
			)
		}
	}
	
	func addNewWord() {
		let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
		guard answer.count > 0 else {
			return
		}
		
		guard isOriginal(word: answer) else {
			wordError(title: "word used already", message: "Be more original!")
			return
		}
		
		guard isPossible(word: answer) else {
			wordError(title: "Word not recognized", message: "You can't just make them up, you know.")
			return
		}
		
		guard isLongEnough(word: answer) else {
			wordError(title: "Word is too short", message: "Must be 3 letters or longer!")
			return
		}
		
		guard isReal(word: answer) else {
			wordError(title: "Word not possible", message: "That's not a real word...")
			return
		}
		
		usedWords.insert(answer, at: 0)
		score += answer.count
		//myTimer.increment()
		newWord = ""
	}
	
	func isOriginal(word: String) -> Bool {
		!usedWords.contains(word) && word != rootWord
	}
	
	func isPossible(word: String) -> Bool {
		var tempWord = rootWord.lowercased()
		
		for letter in word {
			if let pos = tempWord.firstIndex(of: letter) {
				tempWord.remove(at: pos)
			} else {
				return false
			}
		}
		return true
		
	}
	
	func isReal(word: String) -> Bool {
		let checker = UITextChecker()
		let range = NSRange(location: 0, length: word.utf16.count)
		let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
		
		return misspelledRange.location == NSNotFound
	}
	
	func isLongEnough(word: String) -> Bool {
		word.count >= 3
	}
	
	func wordError(title: String, message: String) {
		errorTitle = title
		errorMessage = message + "\n" + "score decremented"
		showingWordError = true
		score -= 1
	}
	
	func startGame() {
		score = 0
		
		if usedWords.count > 0 {
			usedWords = [String]()
		}
		
		if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
			if let startWords = try?
					String(contentsOf: startWordsURL) {
				let allWords = startWords.components(separatedBy: "\n")
				rootWord = allWords.randomElement() ?? "jonathan"
				return
			}
		}
		fatalError("Could not load start.txt from bundle.")
	}
	
	func gameInstructions() {
		showingGameInstructions = true
	}
	
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

//
//  ContentView.swift
//  WordScramble
//
//  Created by Jonathan Gurr on 2/8/21.
//

import SwiftUI


struct ContentView: View {
	
	struct MyTimer {
		var value = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	}
	
	@State private var usedWords = [String]()
	@State private var rootWord = ""
	@State private var userWord = ""
	
	@State private var score = 0
	@State private var highScore = 0
	@State private var scoreMessage = ""
	
	@State private var showingGameInstructions = false
	@State private var showingGameOver = false
	@State private var showingNewWordAskConfirmation = false
	
	@State private var errorTitle = ""
	@State private var errorMessage = ""
	@State private var showingWordError = false
	
	@State private var timeRemaining = 30
	@State private var timer = MyTimer()
	@State private var timerString = "0.00"
	@State private var startTime =  Date()
	@State private var isTimerRunning = false
	
	private let timerIncreaseAmount = 10
	
	private let funnyDismissButton = ["Fine!", "Dang it!", "Well that stinks...", "Oh good grief", "I'm smart, I promise!", "Okie dokie artichokie!", "Shore bud", "¡Cállate!", "Aw fetch!"]
	
	var body: some View {
		NavigationView {
			VStack {
				HStack {
					Button("New word") {
						newWord()
//						showingNewWordAskConfirmation = true
					}
					.foregroundColor(.green)
					.padding()
//					.alert(isPresented: $showingNewWordAskConfirmation) {
//						Alert(title: Text("Warning: This will erase your score"), message: Text("Are you sure you want to add a new word?"), primaryButton: .default(Text("Yes")) {
//							newWord()
//						}, secondaryButton: .cancel(Text("No")))
//					}
					//above commented code not working yet for some reason
					
					
					TextField("Enter your word", text: $userWord, onCommit: addNewWordToList)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.autocapitalization(.none)
						
					VStack {
						Text("High Score: \(highScore)")
							.foregroundColor(.purple)
						
						Text("Score: \(score)")
							.foregroundColor(.orange)
						
					}
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
					nextWord()
				}
				.alert(isPresented: $showingWordError) {
					let randomInt = Int.random(in: 0..<funnyDismissButton.count)
					return Alert(title: Text(errorTitle), message: Text(errorMessage), dismissButton: .default(Text(funnyDismissButton[randomInt])))
				}
				
			}
			.navigationBarItems(
				trailing:
					Text("\(timeRemaining)")
					.onReceive(timer.value) { _ in
						if isTimerRunning {
							timerString = String(format: "%.2f", (Date().timeIntervalSince(startTime)))
							if timeRemaining > 0 {
								timeRemaining -= 1
							} else if timeRemaining <= 0 {
								timeRemaining = 0
								showingWordError = false
								timer.value.upstream.connect().cancel()
								gameOver()
							}
						}
					}
					.alert(isPresented: $showingGameOver) {
						
						Alert(title: Text("Game Over..."), message: Text("You ran out of time. \n\(scoreMessage)"), dismissButton: .default(Text(funnyDismissButton[Int.random(in: 0..<funnyDismissButton.count)])) {
							score = 0
							userWord = ""
							nextWord()
							timer = MyTimer()
							timeRemaining = 60
						})
					})
		}
		
	}
	
	func newWord() {
		showingNewWordAskConfirmation = true
		score = 0
		timer = MyTimer()
		timeRemaining = 60
		nextWord()
	}
	
	func addNewWordToList() {
		let answer = userWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
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
		incrementTimer()
		userWord = ""
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
	
	func incrementTimer() {
		if timeRemaining > 0 {
			timer = MyTimer()
			timeRemaining += timerIncreaseAmount
		}
	}
	
	func nextWord() {
		
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
	
	func gameOver() {
		if score > highScore {
			highScore = score
			scoreMessage = "New High Score: \(highScore)!"
		} else {
			scoreMessage = "Your score was: \(score)"
		}
		showingGameOver = true
	}
	
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}


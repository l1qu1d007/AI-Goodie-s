import google.generativeai as genai #pip install google-generativeai
import pyttsx3 #pip install pyttsx3
import speech_recognition as sr #pip install SpeechRecognition
import tkinter as tk #pip install tk
from tkinter import scrolledtext
import threading #pip install thread
from apikey import api_data


GENAI_API_KEY = api_data

genai.configure(api_key=GENAI_API_KEY)

#Text-to-Speech engine
engine = pyttsx3.init('sapi5')
engine.setProperty('voice', engine.getProperty('voices')[0].id)

def speak(text):
    engine.say(text)
    engine.runAndWait()


def listen_to_command():
    """Speech to Text."""
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        conversation_area.insert(tk.END, "Listening...\n\n")
        recognizer.pause_threshold = 1
        recognizer.adjust_for_ambient_noise(source)
        try:
            audio = recognizer.listen(source, timeout=5, phrase_time_limit=10)
            query = recognizer.recognize_google(audio, language='en-in').lower()
            conversation_area.insert(tk.END, f"You: {query}\n")
            return query
        except sr.UnknownValueError:
            conversation_area.insert(tk.END, "Jarvis: Sorry, I didn't catch that. Please repeat.\n")
            speak("Sorry, I didn't catch that. Please repeat.")
            return "none"
        except sr.RequestError:
            conversation_area.insert(tk.END, "Jarvis: Network error. Please check your connection.\n")
            speak("Network error. Please check your connection.")
            return "none"
        except Exception as e:
            conversation_area.insert(tk.END, f"Jarvis: Error: {e}\n")
            speak("Sorry, I encountered an error.")
            return "none"


def generate_response(query):
  """Generate a response for the given query using Gemini."""
  try:
    model = genai.GenerativeModel("gemini-1.5-flash")
    response = model.generate_content(query, generation_config = genai.GenerationConfig(
        max_output_tokens=75,
        temperature=0.1,))
    print("\n")
    # response = genai.generate_text(prompt=f"Avinash: {query}\nJarvis:")
    return response.text
  except Exception as e:
    return f"Sorry, I encountered an error: {e}"


# Global variable to control the conversation loop
stop_conversation = False


def handle_conversation():
    """Continuously listen to user input and respond."""
    global stop_conversation
    while not stop_conversation:
        query = listen_to_command()
        if query == "none":
            continue

        if "bye" in query or "goodbye" in query:
            conversation_area.insert(tk.END, "Jarvis: Goodbye! Have a great day!\n")
            speak("Goodbye! Have a great day!")
            break

        # Generate and respond to the user's query
        response = generate_response(query)
        conversation_area.insert(tk.END, f"Jarvis: {response}\n")
        speak(response)


def start_conversation():
    """Start the conversation"""
    global stop_conversation
    stop_conversation = False
    conversation_thread = threading.Thread(target=handle_conversation)
    conversation_thread.daemon = True
    conversation_thread.start()
    conversation_area.insert(tk.END, "Hi, i am jarvis. How can i help you ?\n\n")
    conversation_area.see(tk.END)
    speak("Hi, i am jarvis. How can i help you")


def end_conversation():
    """Set the stop_conversation flag to True to end the loop."""
    global stop_conversation
    stop_conversation = True
    conversation_area.insert(tk.END, "Jarvis: Conversation ended manually. Goodbye!\n")
    speak("Conversation ended manually. Goodbye!")
    root.quit()  # Close the application

# Set up the GUI
root = tk.Tk()
root.title("J-A-R-V-I-S")

conversation_area = scrolledtext.ScrolledText(root, wrap=tk.WORD, width=50, height=20, font=("Arial", 12))
conversation_area.pack(padx=10, pady=10)

# Start button
start_button = tk.Button(root, text="Start Conversation", font=("Arial", 12), command=start_conversation)
start_button.pack(pady=5)

# End button
end_button = tk.Button(root, text="End Conversation", font=("Arial", 12), command=end_conversation)
end_button.pack(pady=5)

root.mainloop()

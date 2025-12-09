import React, { useState, useRef } from "react";

//import { FaMicrophone, FaStop } from "react-icons/fa";


// Add these instead:
import { Mic, StopCircle, Volume2, Search, Calendar, HelpCircle } from 'lucide-react';
import './App.css';

const VoiceAssistant: React.FC = () => {
  const [responseAudio, setResponseAudio] = useState<string | null>(null);
  const [recording, setRecording] = useState<boolean>(false);
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Get API URL from environment variable or use local for development
  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

  const startRecording = async () => {
    try {
      setError(null);
      setIsListening(true);
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data);
        }
      };

      mediaRecorder.onstop = async () => {
        setIsProcessing(true);
        const audioBlob = new Blob(audioChunksRef.current, { type: "audio/wav" });
        await sendAudioToBackend(audioBlob);
        
        // Stop all tracks
        stream.getTracks().forEach(track => track.stop());
        setIsProcessing(false);
        setIsListening(false);
      };

      mediaRecorder.start();
      setRecording(true);
      setTranscript("Listening... Speak now!");
    } catch (error) {
      console.error("Microphone access denied:", error);
      setError("Microphone access denied. Please allow microphone permissions.");
      setIsListening(false);
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && recording) {
      mediaRecorderRef.current.stop();
      setRecording(false);
      setTranscript("Processing your voice...");
    }
  };

  const sendAudioToBackend = async (audioBlob: Blob) => {
    try {
      const formData = new FormData();
      formData.append("audio", audioBlob, "recording.wav");

      console.log("Sending audio to:", `${API_BASE_URL}/process_audio`);
      
      const response = await fetch(`${API_BASE_URL}/process_audio`, {
        method: "POST",
        body: formData
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `Server error: ${response.status}`);
      }

      // Handle both audio response and JSON response
      const contentType = response.headers.get('content-type');
      
      if (contentType && contentType.includes('application/json')) {
        // JSON response with audio URL
        const data = await response.json();
        console.log("Response data:", data);
        
        if (data.transcribed_text) {
          setTranscript(`You said: "${data.transcribed_text}"`);
        }
        
        if (data.response) {
          setTranscript(prev => prev + `\nAssistant: ${data.response}`);
        }
        
        if (data.audio_url) {
          // Fetch the audio file from the URL
          const audioResponse = await fetch(`${API_BASE_URL}${data.audio_url}`);
          if (audioResponse.ok) {
            const audioBlob = await audioResponse.blob();
            const audioUrl = URL.createObjectURL(audioBlob);
            setResponseAudio(audioUrl);
          }
        }
      } else {
        // Direct audio response (for backward compatibility)
        const audioBlob = await response.blob();
        const audioUrl = URL.createObjectURL(audioBlob);
        setResponseAudio(audioUrl);
        setTranscript("Voice command processed!");
      }
      
      setError(null);

    } catch (error) {
      console.error("Error sending audio:", error);
      setError(`Error: ${error instanceof Error ? error.message : 'Failed to process audio'}`);
      setTranscript("Failed to process audio. Please try again.");
    }
  };

  const testConnection = async () => {
    try {
      setError(null);
      const response = await fetch(API_BASE_URL);
      if (response.ok) {
        const data = await response.json();
        setTranscript(`✅ API Connected: ${data.message}`);
      } else {
        throw new Error(`API returned status: ${response.status}`);
      }
    } catch (error) {
      setError(`❌ API Connection Failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      setTranscript("Cannot connect to backend API");
    }
  };

  const playAudio = () => {
    if (responseAudio && audioRef.current) {
      audioRef.current.play().catch(e => console.error("Audio play error:", e));
    }
  };

  return (
    <div className="voice-assistant">
      <div className="assistant-container">
        <div className="assistant-header">
          <h1>Voice Assistant</h1>
          <div className="api-info">
            <small>API: {API_BASE_URL}</small>
            <button onClick={testConnection} className="test-btn">
              Test Connection
            </button>
          </div>
        </div>
        
        <div className="assistant-body">
          <div className="response-area">
            <p>How can I help you today?</p>
          </div>
          
          <div className="transcript-area">
            <p>{transcript || "Your voice input will appear here..."}</p>
            
            {error && (
              <div className="error-message">
                {error}
              </div>
            )}
            
            {isProcessing && (
              <div className="processing-message">
                ⏳ Processing your request...
              </div>
            )}

            {responseAudio && (
              <div className="audio-controls">
                <audio 
                  ref={audioRef} 
                  controls 
                  src={responseAudio} 
                  autoPlay 
                  className="audio-player"
                />
                <button onClick={playAudio} className="play-btn">
                  <Volume2 className="response-icon" />
                  Play Again
                </button>
              </div>
            )}
          </div>
          
          <div className="feature-list">
            <div className="feature">
              <Search /> Web Search
            </div>
            <div className="feature">
              <Calendar /> Set Reminders
            </div>
            <div className="feature">
              <HelpCircle /> Answer Questions
            </div>
          </div>
        </div>
        
        <div className="assistant-footer">
          <button
            onClick={recording ? stopRecording : startRecording}
            disabled={isProcessing}
            className={`voice-button ${
              recording 
                ? "recording" 
                : isProcessing 
                ? "processing" 
                : "listening"
            }`}
          >
            {recording ? (
             <StopCircle size={32} />
            ) : isProcessing ? (
              <div className="spinner"></div>
            ) : (
              <Mic size={32} /> 
            )}
          </button>
          <p>
            {isProcessing 
              ? 'Processing...' 
              : recording 
              ? 'Listening...' 
              : 'Press to speak'
            }
          </p>
        </div>
      </div>
    </div>
  );
};

export default VoiceAssistant;
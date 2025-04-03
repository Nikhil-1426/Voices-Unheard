from flask import Flask, jsonify
import google.generativeai as genai
import json

app = Flask(__name__)

# Configure Gemini API
genai.configure(api_key="AIzaSyCTsa5y7IzHAuodBJxIh0WhErFnG6zIhfw")

def fetch_education_resources():
    prompt = (
        "Provide structured data in JSON format for education resources including: "
        "1. Scholarships & Grants (title, description, deadline, amount, eligibility, website)\n"
        "2. Career Opportunities (title, description, location, type, duration, format, level, website)\n"
        "3. Mentorship Programs (title, description, mentors available, duration, website)\n"
        "4. Skill Development (title, description, number of courses, level, format, website)\n"
        "Ensure the response is formatted correctly as a JSON dictionary with appropriate keys."
    )
    
    model = genai.GenerativeModel("gemini-pro")
    response = model.generate_content(prompt)
    
    try:
        return json.loads(response.text)
    except json.JSONDecodeError:
        return {"error": "Invalid JSON format returned from Gemini"}

@app.route("/fetch_resources", methods=["GET"])
def get_resources():
    data = fetch_education_resources()
    return jsonify(data)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

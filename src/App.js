// import logo from './logo.svg';
// import './App.css';

// function App() {
//   return (
//     <div className="App">
//       <header className="App-header">
//         <img src={logo} className="App-logo" alt="logo" />
//         <p>
//           Edit <code>src/App.js</code> and save to reload.
//         </p>
//         <a
//           className="App-link"
//           href="https://reactjs.org"
//           target="_blank"
//           rel="noopener noreferrer"
//         >
//           Learn React
//         </a>
//       </header>
//     </div>
//   );
// }

// export default App;


import React from 'react';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';
import './App.css';
import GoogleSignIn from './GoogleSignIn';
import UserProfile from './UserProfile';
import PrivateRoute from './PrivateRoute';

function App() {
  return (
    <Router>
      <div className="App">
        <header className="App-header">
          <h1>Voices Unheard</h1>
          <nav>
            <ul>
              <li><Link to="/">Home</Link></li>
              <li><Link to="/about">About</Link></li>
              <li><Link to="/features">Features</Link></li>
              <li><Link to="/contact">Contact</Link></li>
              <li><Link to="/google-signin">Google Sign In</Link></li>
              <li><Link to="/profile">Profile</Link></li>
            </ul>
          </nav>
        </header>
        <Routes>
          <Route path="/about" element={
            <section id="about" className="App-section">
              <h2>About Us</h2>
              <p>"Voices Unheard" is a comprehensive web platform designed to amplify the voices of underrepresented communities...</p>
            </section>
          } />
          <Route path="/features" element={
            <section id="features" className="App-section">
              <h2>Features</h2>
              <ul>
                <li>Story Sharing</li>
                <li>Event Organization</li>
                <li>Donation Requests</li>
                <li>Mentorship Matching</li>
                <li>Resource Curation</li>
                <li>Opportunity Recommendations</li>
              </ul>
            </section>
          } />
          <Route path="/contact" element={
            <section id="contact" className="App-section">
              <h2>Contact Us</h2>
              <p>Email: support@voicesunheard.com</p>
            </section>
          } />
          <Route path="/google-signin" element={<GoogleSignIn />} />
          <Route path="/profile" element={<PrivateRoute element={<UserProfile />} />} />
          <Route path="/" element={
            <section className="App-hero">
              <h2 style={{ color: 'red' }}>Amplifying the Voices of Underrepresented Communities</h2>
              <p>Share stories, organize events, and connect with mentors to foster global awareness and understanding.</p>
              <button>Get Started</button>
            </section>
          } />
        </Routes>
        <footer className="App-footer">
          <p>&copy; 2024 Voices Unheard. All rights reserved.</p>
        </footer>
      </div>
    </Router>
  );
}

export default App;





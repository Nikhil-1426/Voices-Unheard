import React, { useState } from 'react';
import './MyProfileMenu.css';
// import { Router } from 'react-router-dom';


const MyProfileMenu = () => {
  const [isOpen, setIsOpen] = useState(false);

  const toggleMenu = () => {
    setIsOpen(!isOpen);
  };

  return (
    
    <div className="profile-menu">
      <button className="profile-button" onClick={toggleMenu}>
        My Profile
      </button>
      {isOpen && (
        <div className="dropdown-menu">
          <a href="#account">My Account</a>
          <a href="#communities">My Communities</a>
          <a href="#signout">Sign Out</a>
        </div>
      )}
    
    </div>
    
  );
};

export default MyProfileMenu;

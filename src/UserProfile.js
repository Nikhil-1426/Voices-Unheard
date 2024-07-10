import React, { useState, useEffect } from 'react';
import { auth, db } from './firebase';
import { doc, getDoc } from "firebase/firestore";
import { onAuthStateChanged } from 'firebase/auth';

function UserProfile() {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        const userRef = doc(db, 'users', currentUser.uid);
        const userProfile = await getDoc(userRef);
        setProfile(userProfile.data());
      } else {
        setProfile(null);
      }
    });

    return () => unsubscribe();
  }, []);

  if (!user) {
    return <div>Please sign in.</div>;
  }

  if (!profile) {
    return <div>Loading profile...</div>;
  }

  return (
    <div>
      <h2>User Profile</h2>
      <img src={profile.photoURL} alt="Profile" />
      <p>Name: {profile.displayName}</p>
      <p>Email: {profile.email}</p>
    </div>
  );
}

export default UserProfile;


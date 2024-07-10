import React, { useState, useEffect } from 'react';
import { db, auth } from './firebase';
import { collection, addDoc, getDocs, doc, deleteDoc } from "firebase/firestore";
import { onAuthStateChanged } from 'firebase/auth';

function Communities() {
  const [communities, setCommunities] = useState([]);
  const [newCommunityName, setNewCommunityName] = useState('');
  const [newCommunityDescription, setNewCommunityDescription] = useState('');
  const [user, setUser] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    const fetchCommunities = async () => {
      const querySnapshot = await getDocs(collection(db, 'communities'));
      const communitiesData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setCommunities(communitiesData);
    };

    fetchCommunities();
  }, []);

  const handleCreateCommunity = async () => {
    if (!newCommunityName || !newCommunityDescription) {
      alert("Please fill out all fields");
      return;
    }

    try {
      await addDoc(collection(db, 'communities'), {
        name: newCommunityName,
        description: newCommunityDescription,
        creatorUid: user.uid,
      });
      setNewCommunityName('');
      setNewCommunityDescription('');
      alert("Community created successfully!");
    } catch (error) {
      console.error("Error creating community: ", error);
    }
  };

  const handleDeleteCommunity = async (id, creatorUid) => {
    if (user.uid !== creatorUid) {
      alert("You are not authorized to delete this community.");
      return;
    }

    try {
      await deleteDoc(doc(db, 'communities', id));
      setCommunities(communities.filter(community => community.id !== id));
      alert("Community deleted successfully!");
    } catch (error) {
      console.error("Error deleting community: ", error);
    }
  };

  return (
    <div>
      <h2>Communities</h2>

      <section>
        <h3>Existing Communities</h3>
        <ul>
          {communities.map(community => (
            <li key={community.id}>
              <h4>{community.name}</h4>
              <p>{community.description}</p>
              {user && community.creatorUid === user.uid && (
                <button onClick={() => handleDeleteCommunity(community.id, community.creatorUid)}>Delete Community</button>
              )}
            </li>
          ))}
        </ul>
      </section>

      {user && (
        <section>
          <h3>Create Community</h3>
          <input
            type="text"
            placeholder="Community Name"
            value={newCommunityName}
            onChange={(e) => setNewCommunityName(e.target.value)}
          />
          <input
            type="text"
            placeholder="Community Description"
            value={newCommunityDescription}
            onChange={(e) => setNewCommunityDescription(e.target.value)}
          />
          <button onClick={handleCreateCommunity}>Create Community</button>
        </section>
      )}
    </div>
  );
}

export default Communities;


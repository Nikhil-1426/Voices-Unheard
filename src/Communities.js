// import React, { useState, useEffect } from 'react';
// import { db, auth } from './firebase';
// import { collection, addDoc, getDocs, doc, deleteDoc } from "firebase/firestore";
// import { onAuthStateChanged } from 'firebase/auth';

// function Communities() {
//   const [communities, setCommunities] = useState([]);
//   const [newCommunityName, setNewCommunityName] = useState('');
//   const [newCommunityDescription, setNewCommunityDescription] = useState('');
//   const [user, setUser] = useState(null);

//   useEffect(() => {
//     const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
//       setUser(currentUser);
//     });

//     return () => unsubscribe();
//   }, []);

//   useEffect(() => {
//     const fetchCommunities = async () => {
//       const querySnapshot = await getDocs(collection(db, 'communities'));
//       const communitiesData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
//       setCommunities(communitiesData);
//     };

//     fetchCommunities();
//   }, []);

//   const handleCreateCommunity = async () => {
//     if (!newCommunityName || !newCommunityDescription) {
//       alert("Please fill out all fields");
//       return;
//     }

//     try {
//       await addDoc(collection(db, 'communities'), {
//         name: newCommunityName,
//         description: newCommunityDescription,
//         creatorUid: user.uid,
//       });
//       setNewCommunityName('');
//       setNewCommunityDescription('');
//       alert("Community created successfully!");
//     } catch (error) {
//       console.error("Error creating community: ", error);
//     }
//   };

//   const handleDeleteCommunity = async (id, creatorUid) => {
//     if (user.uid !== creatorUid) {
//       alert("You are not authorized to delete this community.");
//       return;
//     }

//     try {
//       await deleteDoc(doc(db, 'communities', id));
//       setCommunities(communities.filter(community => community.id !== id));
//       alert("Community deleted successfully!");
//     } catch (error) {
//       console.error("Error deleting community: ", error);
//     }
//   };

//   return (
//     <div>
//       <h2>Communities</h2>

//       <section>
//         <h3>Existing Communities</h3>
//         <ul>
//           {communities.map(community => (
//             <li key={community.id}>
//               <h4>{community.name}</h4>
//               <p>{community.description}</p>
//               {user && community.creatorUid === user.uid && (
//                 <button onClick={() => handleDeleteCommunity(community.id, community.creatorUid)}>Delete Community</button>
//               )}
//             </li>
//           ))}
//         </ul>
//       </section>

//       {user && (
//         <section>
//           <h3>Create Community</h3>
//           <input
//             type="text"
//             placeholder="Community Name"
//             value={newCommunityName}
//             onChange={(e) => setNewCommunityName(e.target.value)}
//           />
//           <input
//             type="text"
//             placeholder="Community Description"
//             value={newCommunityDescription}
//             onChange={(e) => setNewCommunityDescription(e.target.value)}
//           />
//           <button onClick={handleCreateCommunity}>Create Community</button>
//         </section>
//       )}
//     </div>
//   );
// }

// export default Communities;





// import React, { useState, useEffect } from 'react';
// import { db, auth } from './firebase';
// import { collection, addDoc, getDocs, doc, deleteDoc, updateDoc, arrayUnion, getDoc } from "firebase/firestore"; // Import getDoc explicitly
// import { onAuthStateChanged } from 'firebase/auth';

// function Communities() {
//   const [communities, setCommunities] = useState([]);
//   const [newCommunityName, setNewCommunityName] = useState('');
//   const [newCommunityDescription, setNewCommunityDescription] = useState('');
//   const [user, setUser] = useState(null);
//   const [joinedCommunities, setJoinedCommunities] = useState([]);

//   useEffect(() => {
//     const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
//       setUser(currentUser);
//     });

//     return () => unsubscribe();
//   }, []);

//   useEffect(() => {
//     const fetchCommunities = async () => {
//       const querySnapshot = await getDocs(collection(db, 'communities'));
//       const communitiesData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
//       setCommunities(communitiesData);
//     };

//     fetchCommunities();
//   }, []);

//   useEffect(() => {
//     const fetchJoinedCommunities = async () => {
//       if (user) {
//         const userRef = doc(db, 'users', user.uid);
//         const userDoc = await getDoc(userRef);
//         if (userDoc.exists()) {
//           const userData = userDoc.data();
//           setJoinedCommunities(userData.joinedCommunities || []);
//         }
//       }
//     };

//     fetchJoinedCommunities();
//   }, [user]);

//   const handleCreateCommunity = async () => {
//     if (!newCommunityName || !newCommunityDescription) {
//       alert("Please fill out all fields");
//       return;
//     }

//     try {
//       const docRef = await addDoc(collection(db, 'communities'), {
//         name: newCommunityName,
//         description: newCommunityDescription,
//         creatorUid: user.uid,
//         members: [user.uid],
//       });
//       setNewCommunityName('');
//       setNewCommunityDescription('');
//       alert("Community created successfully!");
//       setCommunities(prevCommunities => [...prevCommunities, { id: docRef.id, name: newCommunityName, description: newCommunityDescription, creatorUid: user.uid, members: [user.uid] }]);
//     } catch (error) {
//       console.error("Error creating community: ", error);
//     }
//   };

//   const handleDeleteCommunity = async (id, creatorUid) => {
//     if (user.uid !== creatorUid) {
//       alert("You are not authorized to delete this community.");
//       return;
//     }

//     try {
//       await deleteDoc(doc(db, 'communities', id));
//       setCommunities(communities.filter(community => community.id !== id));
//       alert("Community deleted successfully!");
//     } catch (error) {
//       console.error("Error deleting community: ", error);
//     }
//   };

//   const handleJoinCommunity = async (id) => {
//     try {
//       await updateDoc(doc(db, 'communities', id), {
//         members: arrayUnion(user.uid),
//       });
//       setJoinedCommunities([...joinedCommunities, id]);
//       alert("Joined community successfully!");
//     } catch (error) {
//       console.error("Error joining community: ", error);
//     }
//   };

//   return (
//     <div>
//       <h2>Communities</h2>

//       <section>
//         <h3>Existing Communities</h3>
//         <ul>
//           {communities.map(community => (
//             <li key={community.id}>
//               <h4>{community.name}</h4>
//               <p>{community.description}</p>
//               <p>Category: {community.category}</p>
//               <p>Location: {community.location}</p>
//               {user && community.creatorUid !== user.uid && (
//                 <React.Fragment>
//                   <button onClick={() => handleJoinCommunity(community.id)} disabled={joinedCommunities.includes(community.id)}>Join Community</button>
//                   {joinedCommunities.includes(community.id) && <span style={{ marginLeft: '10px', color: 'green' }}>Joined</span>}
//                 </React.Fragment>
//               )}
//               {user && community.creatorUid === user.uid && (
//                 <button onClick={() => handleDeleteCommunity(community.id, community.creatorUid)}>Delete Community</button>
//               )}
//             </li>
//           ))}
//         </ul>
//       </section>

//       {user && (
//         <section>
//           <h3>Create Community</h3>
//           <input
//             type="text"
//             placeholder="Community Name"
//             value={newCommunityName}
//             onChange={(e) => setNewCommunityName(e.target.value)}
//           />
//           <input
//             type="text"
//             placeholder="Community Description"
//             value={newCommunityDescription}
//             onChange={(e) => setNewCommunityDescription(e.target.value)}
//           />
//           <button onClick={handleCreateCommunity}>Create Community</button>
//         </section>
//       )}
//     </div>
//   );
// }

// export default Communities;




import React, { useState, useEffect } from 'react';
import { db, auth } from './firebase';
import { collection, addDoc, getDocs, doc, deleteDoc, updateDoc, arrayUnion, arrayRemove, getDoc } from "firebase/firestore"; // Import getDoc explicitly
import { onAuthStateChanged } from 'firebase/auth';

function Communities() {
  const [communities, setCommunities] = useState([]);
  const [newCommunityName, setNewCommunityName] = useState('');
  const [newCommunityDescription, setNewCommunityDescription] = useState('');
  const [newCommunityCategory, setNewCommunityCategory] = useState('');
  const [newCommunityQuestions, setNewCommunityQuestions] = useState('');
  const [user, setUser] = useState(null);
  const [userCommunities, setUserCommunities] = useState([]);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        const userRef = doc(db, 'users', currentUser.uid);
        const userProfile = await getDoc(userRef);
        const userCommunities = userProfile.data().communities || [];
        setUserCommunities(userCommunities);
      }
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
    if (!newCommunityName || !newCommunityDescription || !newCommunityCategory || !newCommunityQuestions) {
      alert("Please fill out all fields");
      return;
    }

    try {
      await addDoc(collection(db, 'communities'), {
        name: newCommunityName,
        description: newCommunityDescription,
        category: newCommunityCategory,
        questions: newCommunityQuestions,
        creatorUid: user.uid,
      });
      setNewCommunityName('');
      setNewCommunityDescription('');
      setNewCommunityCategory('');
      setNewCommunityQuestions('');
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

  const handleJoinCommunity = async (communityId) => {
    try {
      const userRef = doc(db, 'users', user.uid);
      await updateDoc(userRef, {
        communities: arrayUnion(communityId),
      });
      setUserCommunities([...userCommunities, communityId]);
      alert("Joined community successfully!");
    } catch (error) {
      console.error("Error joining community: ", error);
    }
  };

  const handleLeaveCommunity = async (communityId) => {
    try {
      const userRef = doc(db, 'users', user.uid);
      await updateDoc(userRef, {
        communities: arrayRemove(communityId),
      });
      setUserCommunities(userCommunities.filter(id => id !== communityId));
      alert("Left community successfully!");
    } catch (error) {
      console.error("Error leaving community: ", error);
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
              <p>Category: {community.category}</p>
              <p>Questions: {community.questions}</p>
              {user && userCommunities.includes(community.id) ? (
                <button onClick={() => handleLeaveCommunity(community.id)}>Leave Community</button>
              ) : (
                <button onClick={() => handleJoinCommunity(community.id)}>Join Community</button>
              )}
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
          <input
            type="text"
            placeholder="Community Category"
            value={newCommunityCategory}
            onChange={(e) => setNewCommunityCategory(e.target.value)}
          />
          <input
            type="text"
            placeholder="Questions"
            value={newCommunityQuestions}
            onChange={(e) => setNewCommunityQuestions(e.target.value)}
          />
          <button onClick={handleCreateCommunity}>Create Community</button>
        </section>
      )}
    </div>
  );
}

export default Communities;

import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Sidebar from './components/Sidebar.jsx';
import Header from './components/Header.jsx';
import MobileNav from './components/MobileNav.jsx';
import ToastContainer from './components/ToastContainer.jsx';
import Dashboard from './pages/Dashboard.jsx';
import Fitness from './pages/Fitness.jsx';
import Running from './pages/Running.jsx';
import Health from './pages/Health.jsx';
import Study from './pages/Study.jsx';

export default function App() {
  return (
    <Router>
      <div className="app-layout">
        <Sidebar />
        <Header />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/fitness" element={<Fitness />} />
            <Route path="/running" element={<Running />} />
            <Route path="/health" element={<Health />} />
            <Route path="/study" element={<Study />} />
          </Routes>
        </main>
        <MobileNav />
        <ToastContainer />
      </div>
    </Router>
  );
}

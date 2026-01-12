import { useContext } from "react";
import { AppContext } from "./context/AppContextProvider";
import Login from "./pages/Login";
import Navbar from "./components/Navbar";
import Sidebar from "./components/Sidebar";
import { Navigate, Route, Routes } from "react-router";
import Dashboard from "./pages/Dashboard";
import SportsManagement from "./pages/SportsManagement";

export default function App() {
    const { aToken } = useContext(AppContext);

    return (
        aToken ? (
            <div className="bg-[#F8F9FD] h-screen overflow-hidden ">
                <Navbar />
                <div className="flex items-start ">
                    <Sidebar />
                    <Routes>
                        <Route path="/" element={<Navigate to="/admin-dashboard" />} />
                        <Route path="/admin-dashboard" element={<Dashboard />} />
                        <Route path="/sports-management" element={<SportsManagement />} />
                    </Routes>
                </div>
            </div>
        ) : (
            <>
                <Login />
            </>
        )
    )
}
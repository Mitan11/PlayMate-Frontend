import { useSelector } from "react-redux";
import { selectAuthToken } from "./redux/auth/authSelectors";
import Login from "./pages/Login";
import Navbar from "./components/Navbar";
import Sidebar from "./components/Sidebar";
import { Navigate, Route, Routes } from "react-router";
import Dashboard from "./pages/Dashboard";
import SportsManagement from "./pages/SportsManagement";
import Box from "@mui/joy/Box";
import AdminAnalytics from "./pages/AdminAnalytics";
import UsersManagement from "./pages/UsersManagement";
import VenueManagement from "./pages/VenueManagement";
import PostsManagement from "./pages/PostsManagement";
import NotFound from "./components/NotFound";
import PrivateRoute from "./components/PrivateRoute";

export default function App() {
    const token = useSelector(selectAuthToken);

    return (
        <Box
            sx={{
                display: "flex",
                flexDirection: "column",
                height: "100vh",
                width: "100vw",
                overflow: "hidden",
                backgroundColor: "#F8F9FD",
            }}
        >
            {token && <Navbar />}
            <Box
                sx={{
                    display: "flex",
                    flex: 1,
                    width: "100%",
                    overflow: "hidden",
                }}
            >
                {token && <Sidebar />}
                <Box
                    sx={{
                        flex: 1,
                        width: "100%",
                        overflowY: "auto",
                        overflowX: "hidden",
                    }}
                >
                    <Routes>
                        <Route path="/" element={token ? <Navigate to="/admin-dashboard" /> : <Login />} />
                        <Route path="/admin-dashboard" element={<PrivateRoute><Dashboard /></PrivateRoute>} />
                        <Route path="/sports-management" element={<PrivateRoute><SportsManagement /></PrivateRoute>} />
                        <Route path="/admin/analytics" element={<PrivateRoute><AdminAnalytics /></PrivateRoute>} />
                        <Route path="/users-management" element={<PrivateRoute><UsersManagement /></PrivateRoute>} />
                        <Route path="/venue-management" element={<PrivateRoute><VenueManagement /></PrivateRoute>} />
                        <Route path="/posts-management" element={<PrivateRoute><PostsManagement /></PrivateRoute>} />
                        <Route path="*" element={<NotFound />} />
                    </Routes>
                </Box>
            </Box>
        </Box>
    );
}
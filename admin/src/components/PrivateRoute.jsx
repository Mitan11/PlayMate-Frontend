import { useSelector } from "react-redux";
import { Navigate } from "react-router";
import { selectAuthToken } from "../redux/auth/authSelectors";

export default function PrivateRoute({ children }) {
    const token = useSelector(selectAuthToken);
    if (!token) return <Navigate to="/" replace />;
    return children;
}

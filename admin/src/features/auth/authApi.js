import axios from "axios";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:4000/api/v1";

const apiClient = axios.create({
    baseURL: API_URL,
    headers: {
        "Content-Type": "application/json",
    },
});

export const authApi = {
    adminLogin: async (email, password) => {
        const response = await apiClient.post(`${API_URL}/admin/admin-login`, {
            email: email.trim().toLowerCase(),
            password: password.trim(),
        });
        return response.data;
    },
};

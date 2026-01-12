import { createContext, useState } from "react"

export const AppContext = createContext()

const AppContextProvider = (props) => {
    const backendUrl = import.meta.env.VITE_BACKEND_URL;
    const [aToken, setaToken] = useState(localStorage.getItem("aToken") ? localStorage.getItem("aToken") : false);
    const value = {
        aToken, 
        setaToken,
        backendUrl
    }

    return (
        <AppContext.Provider value={value}>
            {props.children}
        </AppContext.Provider>
    )
}

export default AppContextProvider   
data PageGroup = PageGroup {
        children :: Set PageGroup,
        pages :: Set Page,
        elements :: Contents,
        permissions :: Permissions,
        template :: String
    }
    
data Page = Page {
        title :: String,
        path :: String,
        localContents :: Contents,
        groupContents :: Contents
    }

data Element
    = StaticHole
    | Hole
    | Markdown String
    | Image String

data Permissions = Permissions {
        read :: Set Role,
        write :: Set Role
    }

data User = User {
        name :: String,
        roles :: Set Role
    }

type Contents = Map Element [Element]
    


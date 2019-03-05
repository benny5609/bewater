role_info {
    serverid number
    roleid   number
    name     string
    new      boolean
}

user {
    uid     number
    token   string
    self    role_info
    roles   [role_info]
    extends <number, role_info>
}

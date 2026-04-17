# Creating the App Registration

1. Go to the [Azure Portal](https://portal.azure.com) > **Microsoft Entra ID** > **App registrations**
2. Click **New registration**
3. Enter a name (e.g. `GroupManager`)
4. Set **Supported account types** to *Accounts in this organizational directory only (Single tenant)*
5. Leave **Redirect URI** blank for now and click **Register**
6. Copy the **Application (client) ID** and **Directory (tenant) ID** from the Overview page
7. Go to **Authentication** > **Add a platform** > **Mobile and desktop applications**
8. Add the following Redirect URI:
   ```
   http://localhost
   ```
9. Under **Advanced settings** on the Authentication page, set **Allow public client flows** to **Yes** and click **Save**
10. Go to **API permissions** > **Add a permission** > **Microsoft Graph** > **Delegated permissions**
11. Add the following permissions:
    - `User.Read`
    - `User.Read.All`
    - `GroupMember.ReadWrite.All`
12. Click **Grant admin consent** (requires admin privileges)

## Required API Permissions (Delegated)

| Permission | Description |
|------------|-------------|
| User.Read | Sign in and read user profile |
| User.Read.All | Read all users' full profiles |
| GroupMember.ReadWrite.All | Read and write group memberships |

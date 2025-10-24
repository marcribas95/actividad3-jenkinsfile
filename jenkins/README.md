# Jenkins with Docker Compose

Jenkins docker compose file (and instructions) to configure your jenkins controller and agent.

## Configuring Jenkins

1. Create the **jenkins_home** folder in your local environment

   ```
   mkdir jenkins_sandbox_home
   ```

2. Create a file named **.env** and add the following:

   ```yml
   JENKINS_HOME_PATH=/home/user/jenkins_sandbox_home # your local jenkins_home path.
   JENKINS_AGENT_SSH_PUBLIC_KEY=<< leave empty for now >>
   ```

3. Run Jenkins controller:

   ```bash
   docker-compose up -d
   ```

4. Get the password to proceed installation:

   ```bash
   docker logs jenkins_sandbox | less
   ```

5. Go to <http://localhost:8080/> and enter the password.

6. Select **Install Suggested Plugins**, create the **admin** user and password, and leave the Jenkins URL <http://localhost:8080/>.

## Configuring Jenkins Agent

1. Use ssh-keygen to create a new key pair:

   ```bash
   ssh-keygen -t rsa -f jenkins_key
   ```

2. Go to Jenkins and click **Manage jenkins** > **Manage credentials**.

3. Under **Stores scoped to Jenkins**, click **Global credentials**, next click **Add credentials** and set the following options:

   - Select **SSH Username with private key**.
   - Limit the scope to **System**.
   - Give the credential an **ID**.
   - Provide a **description**.
   - Enter a **username**.
   - Under Private Key check **Enter directly**. (jenkins_key not pub)
   - Paste the content of private key in the text box.

4. Click **Ok** to save.

5. Paste the public key on the **JENKINS_AGENT_SSH_PUBLIC_KEY** variable, in the **.env** file.

6. Recreate the services:

   ```bash
   docker-compose down
   docker-compose up -d
   ```
Solucion problemas:
🔧 Solución:
Ve a Jenkins: http://localhost:8080

Manage Jenkins → Credentials → System → Global credentials

Encuentra la credencial SSH que creaste

Edita o elimina y crea una nueva con:

Username: jenkins (NO admin)
Private Key: El contenido de jenkins-ssh-key.txt
Luego ve a Manage Jenkins → Nodes → docker-agent

Configure → Verifica que en Credentials esté seleccionada la credencial con username jenkins

Alternativamente, puedes eliminar el nodo y crearlo de nuevo con la configuración correcta:

Manage Jenkins → Nodes
Selecciona docker-agent → Delete Agent
New Node con estos datos exactos:
Name: docker-agent
Type: Permanent Agent
Remote directory: agent
Labels: docker
Launch method: Launch agents via SSH
Host: jenkins-agent-docker
Credentials: Add → SSH Username with private key
Username: jenkins ⚠️ (esto es crítico)
Private Key: Contenido de jenkins-ssh-key.txt
Host Key Verification: Non verifying Verification Strategy
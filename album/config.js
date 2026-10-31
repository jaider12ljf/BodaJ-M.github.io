/* Conexión del álbum con Supabase.
   1. Crea un proyecto gratis en https://supabase.com (botón "Start your project", entrar con GitHub).
   2. En el proyecto: SQL Editor → pega todo supabase-setup.sql → Run.
   3. Project Settings → API: copia "Project URL" y la clave "anon public" aquí abajo.
   La clave anon es pública por diseño (los permisos los pone supabase-setup.sql). Nunca pegues aquí la "service_role". */
window.ALBUM_CONFIG = {
  supabaseUrl: 'https://vozkjrgxrxtemgrzaypc.supabase.co',
  supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvemtqcmd4cnh0ZW1ncnpheXBjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0Njg0NDQsImV4cCI6MjEwOTA0NDQ0NH0.72v0ueO9cnFHsYHxWF6eMzszk-mdBhKgoK996jA_avI'
};

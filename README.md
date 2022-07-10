# so-deploy

so-deploy es una herramienta para facilitar el proceso de deploy de los proyectos.

## Uso

Al ejecutar el script sobre el nombre de un repositorio, se pueden pasar los siguientes parametros **en orden**:
* -t | --target: Cambia el directorio donde sera ejecutado el script. Por defecto se ejecuta en el directorio actual.
* -s | --structure: Cambia la ruta donde el script debe buscar los makefiles para cada proyecto o dependencia. Por defecto va a ser el directorio en donde reside cada uno.
* -r | --rule: Cambia la regla del makefile para compilar los proyectos. El valor por defecto es `all`.
* -l | --lib: Agrega una dependencia externa para compilar e instalar. (Se especifica user y nombre del repositorio en github, ej: `sisoputnfrba/so-nivel-gui-library`)
* -d | --dependency: Agrega una dependencia interna del proyecto para compilar e instalar. (Forman parte del repositorio a deployar y se especifica una ruta dentro del repositorio a donde reside la dependencia).
* -p | --project: Agrega un proyecto a compilar del repositorio. (Al igual que las dependencias se puede pasar una ruta a los proyectos)

Para ver informacion de como usarlo, ejecutar con la opcion -h (help) `./deploy.sh -h`

### Ejemplo

```
./deploy.sh -l=sisoputnfrba/so-nivel-gui-library -d=sockets -p=consola -p=kernel -p=memoria tp-20XX-XC-ejemplo
```

### Requerimientos

so-deploy requiere que los proyectos y dependencias tengan un makefile encargado de compilar correctamente a cada uno.

La estructura por defecto es la siguiente (aunque puede ser modificada usando el flag `-s`):

```
repo
│
└─── Proyecto/
|     └─── makefile
└─── Dependencia/
      └─── makefile
```

## Contacto

Si encontras algun error en el script o tenes alguna sugerencia, ¡no dudes en levantar un issue en este repositorio para hacernos saber!

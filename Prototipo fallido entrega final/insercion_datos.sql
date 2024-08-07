-- Inserción de datos
-- Insertar Administradores (10)
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (1, 'Ankunding-Marquardt', '33-77179407-1', '1100656503', 'bbrewitt0@huffingtonpost.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (2, 'Oberbrunner-Jacobi', '23-36919033-1', '1134185143', 'kruzic1@dmoz.org');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (3, 'Schmidt-Jacobi', '20-18851079-0', '1168450779', 'cfausset2@surveymonkey.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (4, 'Fadel-Lowe', '27-46109228-2', '1100651188', 'ltester3@cnbc.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (5, 'Sipes-Jenkins', '20-66066120-3', '1193127790', 'jives4@oaic.gov.au');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (6, 'Renner, Boyle and Tillman', '33-35290917-1', '1172853216', 'dcoggon5@time.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (7, 'Stanton-Kunze', '23-83924505-3', '1174660157', 'oolpin6@tripadvisor.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (8, 'Zboncak Group', '30-75414810-0', '1156895922', 'gmackimm7@hc360.com');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (9, 'Hills-Casper', '20-34015163-3', '1161001442', 'khaggett8@wordpress.org');
insert into Administradores (id_administrador, nombre, CUIT, telefono, email) values (10, 'Rath Group', '30-21187055-2', '1192933846', 'hvolet9@admin.ch');
-- Insertar Encargados (10)
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (1, 'Garvin', 'Lambole', '20-05785675-6', '505954');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (2, 'Jefferey', 'Haxby', '99-94897644-8', '472932.6');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (3, 'Blane', 'Follis', '23-34982506-6', '368668');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (4, 'Barbara', 'Lynde', '99-40578871-3', '540302.2');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (5, 'Dani', 'Arnholdt', '30-86175972-0', '605277.96');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (6, 'Lorene', 'Crookes', '50-06780797-1', '1413595');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (7, 'Bil', 'McGonigal', '34-30686084-7', '1684194.6');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (8, 'Gretchen', 'Syce', '50-32403123-0', '2534242.1');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (9, 'Theodore', 'Mobley', '50-35057518-5', '669224.1');
insert into Encargados (id_encargado, nombre, apellido, CUIL, salario) values (10, 'Aurea', 'Bartoshevich', '50-05062107-9', '1440707');
-- Insertar Consorcios (10)
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (1, '33-75759115-3', '66 Walton Crossing', 572, 10, 1);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (2, '30-78335263-3', '857 Muir Trail', 483, 9, 2);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (3, '30-54927417-1', '35 Lake View Pass', 598, 2, 3);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (4, '30-32286770-1', '11330 Johnson Street', 539, 1, 4);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (5, '23-13590496-2', '2 Nobel Place', 390, 2, 5);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (6, '20-65346667-0', '28 Anniversary Terrace', 648, 3, 6);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (7, '20-26751285-1', '59 Mifflin Hill', 496, 8, 7);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (8, '30-50642535-2', '83 Haas Trail', 380, 3, 8);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (9, '20-08965651-3', '73 Lindbergh Drive', 626, 2, 9);
insert into Consorcios (id_consorcio, CUIT, direccion, unidades_funcionales, id_administrador, id_encargado) values (10, '23-78074622-1', '678 Thackeray Terrace', 641, 3, 10);
-- Insertar Proveedores (10)
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (1, 'Wilkinson-Bins', '1190313781', 'jmeeking0@cnn.com', 'Painter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (2, 'Kuhlman, Kulas and Bayer', '1103701294', 'medleston1@uiuc.edu', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (3, 'Breitenberg, McClure and Moore', '1198791801', 'aeberz2@pagesperso-orange.fr', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (4, 'Hammes, Beatty and Hodkiewicz', '1189837366', 'enorree3@blogger.com', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (5, 'Purdy and Sons', '1125650971', 'mavraham4@fotki.com', 'Plumber');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (6, 'Carroll-Hermiston', '1199579134', 'nmccumesky5@ibm.com', 'Plumber');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (7, 'Harris Inc', '1141568649', 'dsturte6@taobao.com', 'Carpenter');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (8, 'Wunsch Group', '1162550807', 'crymell7@booking.com', 'Electrician');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (9, 'Blanda LLC', '1197744988', 'hmarke8@baidu.com', 'Landscaper');
insert into Proveedores (id_proveedor, razon_social, telefono, email, descripcion_servicio) values (10, 'Wisozk-Denesik', '1164383567', 'hgriffiths9@meetup.com', 'Landscaper');
-- Para insertar expensas, usar SP "sp_insertar_expensa_consorcio"
#pragma once

#include <EntitasPP/ISystem.h>
#include <EntitasPP/Pool.h>
#include <Singleton/Singleton.h>
#include <LuaBridge/RefCountedPtr.h>
#include <hexmap/hexmap.h>

namespace Chestnut {
namespace Ball {

class MapSystem :
	public  EntitasPP::ISystem, public EntitasPP::ISetRefPoolSystem, public EntitasPP::IInitializeSystem, public EntitasPP::IFixedExecuteSystem {

public:
	
	MapSystem() = default;
	virtual ~MapSystem();

	
	void SetPool(RefCountedPtr<EntitasPP::Pool> pool);

	void Initialize();

	void FixedExecute();

	void FindPath(int index, struct vector3 start, struct vector3 dst);

protected:

private:
	RefCountedPtr<Chestnut::EntitasPP::Pool> _pool;
	struct HexMap *_map;

};

}
}